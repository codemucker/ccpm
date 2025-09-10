# PM Anti-Cheat Detection System

Detects hardcoded responses, cheat patterns, simulation code, and other non-genuine implementations in your codebase.

## Usage

```bash
/pm:anti-cheat [path]           # Analyze specific path for cheat patterns
/pm:anti-cheat                  # Analyze entire project
```

## What It Detects

### Cheat Patterns
- ✅ **Hardcoded responses** that should be computed
- ✅ **Keyword-based fake intelligence** systems
- ✅ **Mock/stub implementations** in production code
- ✅ **Random/time-based responses** masking hardcoded logic
- ✅ **Early returns** with fake values
- ✅ **Debug modes** in production code
- ✅ **Bypass conditions** skipping real processing
- ✅ **TODO/FIXME** in production code
- ✅ **Caller-dependent behavior** variations
- ✅ **Lookup tables** masquerading as complex logic

### Anti-Patterns
- Fake API responses instead of real service calls
- Hardcoded test data in business logic
- Simulation code pretending to be real functionality
- Feature flags that permanently bypass implementation
- Magic numbers without explanation

## Examples

```bash
# Check specific component for cheats
/pm:anti-cheat src/auth/

# Full project cheat detection
/pm:anti-cheat

# Common as part of fix workflow
/pm:fix-all
```

## Integration

Part of the complete quality workflow:
1. `/pm:code-review` - SOLID principles check
2. `/pm:anti-cheat` - Cheat pattern detection  
3. `/pm:validate` - Runtime validation
4. `/pm:plan-fixes` - Generate linear fix plan

Zero tolerance for cheat patterns in production code!