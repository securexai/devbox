# Pull Request

## Description

<!-- Provide a brief description of the changes in this PR -->

## Type of Change

<!-- Mark the relevant option with an 'x' -->

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Configuration change
- [ ] Refactoring (no functional changes)

## Changes Made

<!-- List the main changes made in this PR -->

-
-
-

## Testing Performed

<!-- Describe the testing you performed to verify your changes -->

- [ ] Tested on fresh Multipass VM
- [ ] Validated cloud-init configuration: `cloud-init schema --config-file cloudops-config-v2.yaml --annotate`
- [ ] Verified SSH connectivity
- [ ] Tested VS Code Remote SSH connection
- [ ] Tested Devbox functionality (if applicable)

## Documentation Checklist

<!-- Verify all documentation requirements are met -->

- [ ] Updated relevant documentation files
- [ ] Ran markdown linter and fixed issues
- [ ] Updated CHANGELOG.md with changes
- [ ] Updated version dates to ISO 8601 format (YYYY-MM-DD)
- [ ] Verified all internal links work correctly
- [ ] Updated "Last Updated" dates where applicable
- [ ] Reviewed for consistent terminology (cloudops vs Devbox)
- [ ] Added/updated code examples where needed

## Configuration Changes

<!-- If this PR modifies cloudops-config-v2.yaml -->

- [ ] Validated with `cloud-init schema --annotate`
- [ ] Tested with fresh VM launch
- [ ] Updated documentation to reflect config changes
- [ ] Verified backward compatibility or documented breaking changes

## Security Considerations

<!-- Answer if this PR has security implications -->

- [ ] No secrets or credentials in code/config
- [ ] Reviewed for security best practices
- [ ] No exposure of sensitive information

## Related Issues

<!-- Link any related issues -->

Fixes #
Related to #

## Screenshots (if applicable)

<!-- Add screenshots to help explain your changes -->

## Additional Notes

<!-- Any additional information that reviewers should know -->

---

## Reviewer Checklist

<!-- For reviewers -->

- [ ] Code/config changes are logical and well-structured
- [ ] Documentation is clear and accurate
- [ ] No hardcoded secrets or sensitive data
- [ ] Changes follow project conventions
- [ ] CHANGELOG.md is updated appropriately
- [ ] All links and references are valid
