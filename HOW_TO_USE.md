# 分支对比工具使用指南 / Branch Comparison Tool Guide

## 快速开始 / Quick Start

### 中文说明

本工具用于比对 WHPocketNotes 仓库中的不同分支，识别可能遗漏的合并代码。

#### 查看报告

1. **主报告**: 查看 `BRANCH_COMPARISON_REPORT.md` - 包含完整的分支对比分析
2. **详细分析**: 查看 `DETAILED_DIFF_ANALYSIS.md` - 包含文件级别的详细变更说明

#### 运行对比工具

```bash
# 对比所有分支与 main 分支
./branch-comparison.sh main

# 对比所有分支与 develop 分支
./branch-comparison.sh develop
```

#### 主要发现

根据分析，发现以下分支包含未合并的代码：

1. **copilot/add-ai-input-functionality** (优先级: 高)
   - 5 个提交未合并
   - 包含 AI 集成功能和多个 bug 修复
   - 建议优先合并

2. **copilot/analyze-project-structure** (优先级: 中)
   - 2 个提交未合并
   - 包含项目分析文档
   - 需要先更新到最新的 main 分支

---

### English Instructions

This tool is used to compare different branches in the WHPocketNotes repository and identify potentially missed merges.

#### View Reports

1. **Main Report**: See `BRANCH_COMPARISON_REPORT.md` - Complete branch comparison analysis
2. **Detailed Analysis**: See `DETAILED_DIFF_ANALYSIS.md` - Detailed file-level change descriptions

#### Run Comparison Tool

```bash
# Compare all branches with main
./branch-comparison.sh main

# Compare all branches with develop
./branch-comparison.sh develop
```

#### Key Findings

Based on the analysis, the following branches contain unmerged code:

1. **copilot/add-ai-input-functionality** (Priority: High)
   - 5 unmerged commits
   - Contains AI integration features and multiple bug fixes
   - Recommended to merge first

2. **copilot/analyze-project-structure** (Priority: Medium)
   - 2 unmerged commits
   - Contains project analysis documentation
   - Should be updated to latest main branch first

---

## 文件说明 / File Descriptions

| 文件 / File | 说明 / Description |
|------------|-------------------|
| `BRANCH_COMPARISON_REPORT.md` | 完整的分支对比报告，包含所有发现和建议 / Complete branch comparison report with all findings and recommendations |
| `DETAILED_DIFF_ANALYSIS.md` | 详细的文件级别差异分析和测试清单 / Detailed file-level diff analysis and testing checklist |
| `branch-comparison.sh` | 自动化分支对比工具脚本 / Automated branch comparison tool script |
| `branch-graph.txt` | Git 分支图形化展示 / Git branch graph visualization |
| `HOW_TO_USE.md` | 本文件 - 使用指南 / This file - Usage guide |

---

## 下一步建议 / Next Steps

### 1. 合并 AI 功能分支 / Merge AI Feature Branch

```bash
git checkout main
git pull origin main
git merge copilot/add-ai-input-functionality
# 测试功能 / Test features
# 解决冲突（如果有）/ Resolve conflicts if any
git push origin main
```

### 2. 更新项目分析分支 / Update Project Analysis Branch

```bash
git checkout copilot/analyze-project-structure
git merge main
# 解决冲突 / Resolve conflicts
git checkout main
git merge copilot/analyze-project-structure
git push origin main
```

---

## 支持 / Support

如有问题，请查看：
- `BRANCH_COMPARISON_REPORT.md` - 详细报告
- `DETAILED_DIFF_ANALYSIS.md` - 技术细节

For questions, please see:
- `BRANCH_COMPARISON_REPORT.md` - Detailed report
- `DETAILED_DIFF_ANALYSIS.md` - Technical details

---

**工具版本 / Tool Version:** 1.0  
**生成日期 / Generated:** 2026-02-02
