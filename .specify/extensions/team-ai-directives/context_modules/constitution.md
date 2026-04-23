# Team Constitution

1. **Human Oversight Is Mandatory**
   Every autonomous contribution must receive human review before merge. Agents operate within guardrails; engineers are accountable for final outcomes.

2. **Build for Observability and Reproducibility**
   All features must include logging, metrics, and deterministic workflows so issues can be traced quickly.

3. **Security by Default**
   Follow least privilege for credentials, validate all inputs, and prefer managed secrets. Never ship hard-coded tokens.

4. **Tests Drive Confidence**
   Write automated tests before or alongside new logic. Refuse to ship when critical coverage is missing.

5. **Documentation Matters**
   Capture assumptions, API contracts, and hand-off notes in the repo. Agents and humans rely on clear context to move fast safely.

6. **Stateless Services**
   All services should be designed to be stateless, meaning they do not maintain any internal state between requests. This ensures scalability, reliability, and ease of deployment in cloud environments. State should be externalized to databases or caches as needed.

7. **Zero Trust Security Model**
    Adopt a zero trust approach where no entity is trusted by default, even if it's inside the network perimeter. Always verify and authenticate every request, implement least privilege access, and continuously monitor for threats.

8. **Think Before Coding**
    Don't assume. Don't hide confusion. Surface tradeoffs. State assumptions explicitly—if uncertain, ask rather than guess. Present multiple interpretations when ambiguity exists. Push back when warranted if a simpler approach is available. Stop when confused and name what's unclear.

9. **Simplicity First**
    Minimum code that solves the problem. Nothing speculative. No features beyond what was asked, no abstractions for single-use code, no "flexibility" that wasn't requested, no error handling for impossible scenarios. If 200 lines could be 50, rewrite it. Every senior engineer should agree the solution is not overcomplicated.

10. **Surgical Changes**
    Touch only what you must. Clean up only your own mess. When editing existing code, don't "improve" adjacent code, comments, or formatting. Don't refactor things that aren't broken. Match existing style, even if you'd do it differently. Remove imports/variables/functions that YOUR changes made unused, but don't remove pre-existing dead code unless asked.

11. **Goal-Driven Execution**
    Define success criteria. Loop until verified. Transform imperative tasks into verifiable goals with clear success metrics. For multi-step tasks, state a brief plan with what each step accomplishes and how to verify it. Strong success criteria enable autonomous looping; weak criteria require constant clarification.

12. **Memory as the Harness Core**
    Memory transforms execution into learning. Every interaction generates traces—outputs, failures, decisions—that should accumulate into knowledge. Storing experiences is not the same as learning; what matters is deciding what to keep, how to merge it with what the system already knows, and what to forget. Without memory, every execution starts from scratch. With memory, execution compounds. Design the memory layer to filter signal from noise, consolidate conflicting learnings, and make knowledge reusable across future tasks.