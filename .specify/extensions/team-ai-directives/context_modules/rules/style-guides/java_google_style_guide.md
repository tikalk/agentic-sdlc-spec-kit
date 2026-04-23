# Rule: Java Style Guide

## Checklist
- Follow Google Java Style Guide conventions (4-space indents, 100 char line limit, camelCase for methods/variables, PascalCase for classes).
- Use JavaDoc comments for all public classes, methods, and fields describing purpose, parameters, return values, and exceptions.
- See @rule:style-guides/java_null_safety_and_optional.md for null safety and Optional usage guidelines.
- Use meaningful variable and method names that clearly express intent.
- Keep methods focused and small (ideally under 20 lines, max 50 lines).
- Use `final` for immutable variables and method parameters when appropriate.
- Run `google-java-format` or `checkstyle` before submitting changes.
- Use modern Java features (Java 17+): records, pattern matching, sealed classes, text blocks where appropriate.
- Prefer `var` for local variables when the type is obvious from the right-hand side.
- One top-level class per file, file name matches class name.
- Group imports: static imports, then standard library, then third-party, then project imports.

## Rationale
Consistency and readability help both humans and agents maintain the codebase confidently. Following established style guides ensures code integrates seamlessly with existing codebases and tooling.

