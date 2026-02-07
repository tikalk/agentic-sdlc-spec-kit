#!/usr/bin/env python3
"""
Migrate from external_skills.md to skills.json

One-time migration script to convert external skills to versioned skills.
"""

import re
import json
from pathlib import Path
from typing import List, Dict
from dataclasses import asdict
from datetime import datetime


def parse_external_skills(filepath: Path) -> List[Dict]:
    """Parse external_skills.md and extract skill information"""
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    skills = []
    
    # Pattern to match skill entries
    # Looking for: #### Skill Name followed by bullet points with URLs
    skill_pattern = r'####\s+(.+?)\n(.+?)(?=####|\Z)'
    
    for match in re.finditer(skill_pattern, content, re.DOTALL):
        skill_name = match.group(1).strip()
        skill_content = match.group(2)
        
        skill_info = {
            'name': skill_name,
            'source': None,
            'skill_url': None,
            'description': None,
            'categories': []
        }
        
        # Extract source
        source_match = re.search(r'\*\*Source\*\*:\s*(.+)', skill_content)
        if source_match:
            skill_info['source'] = source_match.group(1).strip()
        
        # Extract skill URL
        url_match = re.search(r'\*\*Skill URL\*\*:\s*(.+)', skill_content)
        if url_match:
            skill_info['skill_url'] = url_match.group(1).strip()
        
        # Extract description
        desc_match = re.search(r'\*\*Description\*\*:\s*(.+?)(?=\n\*|$)', skill_content, re.DOTALL)
        if desc_match:
            skill_info['description'] = desc_match.group(1).strip().replace('\n', ' ')
        
        # Extract categories
        cat_match = re.search(r'\*\*Categories\*\*:\s*(.+)', skill_content)
        if cat_match:
            cats = cat_match.group(1).strip()
            skill_info['categories'] = [c.strip() for c in cats.split(',')]
        
        skills.append(skill_info)
    
    return skills


def convert_url_to_skill_ref(skill_url: str) -> str:
    """Convert raw GitHub URL to skill reference"""
    # Convert:
    # https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/SKILL.md
    # to:
    # github:vercel-labs/agent-skills/react-best-practices
    
    if 'raw.githubusercontent.com' in skill_url:
        # Extract org/repo/skill from raw URL
        pattern = r'raw\.githubusercontent\.com/([^/]+)/([^/]+)/[^/]+/skills/([^/]+)/SKILL\.md'
        match = re.match(pattern, skill_url)
        if match:
            org, repo, skill = match.groups()
            return f"github:{org}/{repo}/{skill}"
    
    return None


def migrate_skills(external_skills_path: Path, manifest_path: Path, 
                   dry_run: bool = True) -> Dict:
    """Migrate external skills to skills.json"""
    
    # Parse external skills
    skills = parse_external_skills(external_skills_path)
    
    if not skills:
        return {
            'success': False,
            'error': 'No skills found in external_skills.md',
            'migrated': 0,
            'failed': 0
        }
    
    # Create manifest structure
    manifest = {
        'version': '1.0.0',
        'skills': {},
        'lockfile': {},
        'config': {
            'registry_url': 'https://registry.agentic-sdlc.io',
            'auto_update': False,
            'evaluation_required': False,
            'migrated_from_external': True,
            'migration_date': datetime.utcnow().isoformat() + 'Z'
        }
    }
    
    migrated = 0
    failed = 0
    failed_skills = []
    
    for skill in skills:
        skill_ref = convert_url_to_skill_ref(skill['skill_url'])
        
        if not skill_ref:
            failed += 1
            failed_skills.append({
                'name': skill['name'],
                'reason': 'Could not convert URL to skill reference'
            })
            continue
        
        # Add to manifest
        manifest['skills'][skill_ref] = {
            'version': 'main',  # Default to main branch
            'installed_at': datetime.utcnow().isoformat() + 'Z',
            'source': 'github',
            'metadata': {
                'name': skill['name'],
                'description': skill['description'],
                'categories': skill['categories'],
                'author': skill['source'].replace('https://github.com/', '').split('/')[0] if skill['source'] else 'unknown'
            }
        }
        
        manifest['lockfile'][skill_ref] = {
            'resolved': skill['skill_url'],
            'integrity': None
        }
        
        migrated += 1
    
    # Save manifest
    if not dry_run:
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Backup existing skills.json if present
        if manifest_path.exists():
            backup_path = manifest_path.with_suffix('.json.backup')
            manifest_path.rename(backup_path)
            print(f"Backed up existing manifest to {backup_path}")
        
        with open(manifest_path, 'w') as f:
            json.dump(manifest, f, indent=2)
        
        print(f"\n✓ Migration complete!")
        print(f"  Manifest saved to: {manifest_path}")
    
    return {
        'success': True,
        'migrated': migrated,
        'failed': failed,
        'failed_skills': failed_skills,
        'manifest': manifest if dry_run else None
    }


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Migrate external_skills.md to skills.json'
    )
    parser.add_argument(
        '--dry-run', 
        action='store_true',
        help='Preview migration without making changes'
    )
    parser.add_argument(
        '--external-file',
        type=Path,
        default=Path('external_skills.md'),
        help='Path to external_skills.md'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=Path('.specify/skills.json'),
        help='Output path for skills.json'
    )
    parser.add_argument(
        '--report',
        action='store_true',
        help='Generate detailed migration report'
    )
    
    args = parser.parse_args()
    
    # Find external_skills.md
    if not args.external_file.exists():
        # Try common locations
        possible_paths = [
            Path('external_skills.md'),
            Path('agentic-sdlc-team-ai-directives/skills/external_skills.md'),
            Path('../agentic-sdlc-team-ai-directives/skills/external_skills.md')
        ]
        
        for path in possible_paths:
            if path.exists():
                args.external_file = path
                break
        else:
            print(f"Error: external_skills.md not found")
            return 1
    
    print(f"Found external_skills.md at: {args.external_file}")
    print(f"{'DRY RUN - ' if args.dry_run else ''}Migrating skills...\n")
    
    result = migrate_skills(
        args.external_file,
        args.output,
        dry_run=args.dry_run
    )
    
    if not result['success']:
        print(f"Error: {result['error']}")
        return 1
    
    print(f"Migration Summary:")
    print(f"  Successfully parsed: {result['migrated']} skills")
    print(f"  Failed to parse: {result['failed']} skills")
    
    if result['failed_skills']:
        print(f"\nFailed skills:")
        for skill in result['failed_skills']:
            print(f"  - {skill['name']}: {skill['reason']}")
    
    if args.report and result.get('manifest'):
        print(f"\n\nGenerated Manifest Preview:")
        print(json.dumps(result['manifest'], indent=2))
    
    if args.dry_run:
        print(f"\n\nTo execute migration, run:")
        print(f"  python migrate-external-skills.py --no-dry-run")
    
    return 0


if __name__ == '__main__':
    exit(main())
