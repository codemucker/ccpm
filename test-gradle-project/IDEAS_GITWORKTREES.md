# Git Worktrees for Parallel Agent Execution

## Current State
CCPM currently executes multiple agents in parallel within a single git worktree. This enables concurrent task execution but has limitations around conflict management and true isolation.

## Vision: Worktree-Based Parallel Execution

### Core Concept
Each parallel task gets its own git worktree + branch, allowing true isolation of agent work with intelligent conflict detection and resolution.

## Conflict Prevention Strategies

### 1. File-Level Conflict Detection
```bash
# Pre-execution analysis
Task A: touches [src/auth/, tests/auth/]
Task B: touches [src/api/, tests/api/] 
Task C: touches [src/auth/user.ts, src/shared/] # CONFLICT with A!

# Auto-decision: A and C → serial, B → parallel
```

### 2. Dependency Graph Analysis
```bash
# Smart dependency mapping
Task 1: "Setup database schema" → foundation for all data tasks
Task 2: "Create user API" → depends on Task 1  
Task 3: "Create product API" → depends on Task 1, may conflict with Task 2

# Execution plan: Task 1 first, then Tasks 2+3 in parallel from common base
```

### 3. Smart Branch Strategy
```bash
main
├── feature/task-001-db-schema (sequential foundation)
├── feature/task-002-user-api (parallel from main+001)  
└── feature/task-003-product-api (parallel from main+001)
```

## Conflict Resolution & Rollback

### Three-Tier Conflict Handling

**LEVEL 1: Simple conflicts** (imports, formatting)
→ Auto-resolve with conflict resolution tools

**LEVEL 2: Moderate conflicts** (method signatures, schemas)  
→ Pause parallel execution, request human review

**LEVEL 3: Semantic conflicts** (architecture changes)
→ Full rollback, convert to serial execution with preserved summaries

### Automatic Serial Conversion
```bash
# Conflict thresholds
MAX_CONFLICTS_PER_MERGE: 3
MAX_ROLLBACKS_PER_EPIC: 2
COMPLEXITY_THRESHOLD: "high"

# When exceeded → rollback with work preservation
```

## Work Summary Preservation

### Implementation Context Capture
```json
{
  "task": "002-user-api",
  "approach": "JWT auth with refresh tokens", 
  "key_decisions": [
    "Used bcrypt for password hashing",
    "Implemented role-based permissions",
    "Created middleware for auth validation"
  ],
  "completed_files": ["auth/service.ts", "auth/middleware.ts"],
  "test_patterns": ["Given user credentials, when authenticating..."],
  "blockers_encountered": ["Shared types conflict with product API"],
  "time_spent": "2.5 hours",
  "completion_percentage": "85%"
}
```

### Fast Re-Implementation
- Agent gets full context from summary
- Avoids previous mistakes and conflicts
- Estimated re-implementation time: ~20% of original time
- Clean implementation in serial branch

## Smart Coordination Strategies

### Pre-Flight Conflict Analysis
```bash
analyze_task_conflicts(epic_tasks) {
  file_conflicts = detect_file_overlap()
  dependency_conflicts = analyze_dependencies() 
  integration_conflicts = check_shared_interfaces()
  
  return execution_strategy: "parallel" | "serial" | "hybrid"
}
```

### Hybrid Execution Model
```bash
Epic: "User Management System"
├── Phase 1: [DB Schema] (serial - foundation)
├── Phase 2: [User API, Auth API] (parallel - independent)  
├── Phase 3: [Integration Tests] (serial - needs both APIs)
└── Phase 4: [UI Components] (parallel - separate concerns)
```

### Progressive Learning
```bash
CONFLICT_PATTERNS: {
  "shared_types_modification": "HIGH_RISK - serialize",
  "package_json_changes": "MEDIUM_RISK - coordinate", 
  "separate_feature_files": "LOW_RISK - parallel_ok"
}
```

## Implementation Architecture

### Core Components Needed

1. **Worktree Manager**: Creates/manages/cleans up worktrees
2. **Conflict Analyzer**: Pre-execution conflict detection
3. **Merge Coordinator**: Intelligent merging with conflict detection
4. **Rollback Engine**: Graceful rollback with summary preservation
5. **Context Preserver**: Captures implementation intent and decisions
6. **Learning System**: Builds conflict pattern knowledge

### Workflow Integration
```bash
# Enhanced commands
/pm:epic-start feature-name --worktrees  # Enable worktree mode
/pm:epic-merge feature-name              # Intelligent merge coordination
/pm:rollback epic-name                   # Graceful rollback with summaries
/pm:conflicts analyze feature-name       # Pre-flight conflict analysis
```

## Success Metrics

- **Parallel Success Rate**: % of epics completing without rollback
- **Rollback Recovery Time**: Speed of re-implementation with summaries  
- **Conflict Prediction Accuracy**: How well the system predicts conflicts
- **Development Velocity**: Overall speed improvement vs single-worktree approach

## Benefits

### For Developers
- **True Isolation**: No stepping on each other's work
- **Risk Mitigation**: Easy rollback without losing progress
- **Context Preservation**: Fast recovery from conflicts
- **Intelligent Planning**: System learns optimal execution strategies

### For Teams  
- **Parallel Scaling**: More tasks can run simultaneously
- **Conflict Reduction**: Fewer integration surprises
- **Knowledge Capture**: Implementation decisions preserved
- **Adaptive Workflows**: System improves over time

## Philosophy

**Optimistic Parallel → Graceful Serial Fallback**

Start with parallel execution, monitor for conflicts, rollback gracefully with preserved context, and learn for next time. Make rollback cheap and learning automatic so the system becomes smarter about when to use worktrees vs. serial execution.

The key insight: **Failure is data**. Each rollback teaches the system better conflict prediction for future epics.