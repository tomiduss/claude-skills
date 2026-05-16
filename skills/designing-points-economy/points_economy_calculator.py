#!/usr/bin/env python3
"""
Points Economy Calculator - Template for generating Excel workbooks

This script demonstrates the framework. Claude can adapt this to:
1. Generate Excel workbooks with all modes
2. Export CSV templates
3. Create validation reports

Usage:
    python points_economy_calculator.py --output economy_analysis.xlsx
"""

import pandas as pd
from dataclasses import dataclass
from typing import Dict, List, Tuple


@dataclass
class ActionEvaluation:
    """Multi-dimensional evaluation of an action"""
    name: str
    community_score: int  # 1-10: Engagement/reach value
    quality_score: int     # 1-10: Enforceability/quality
    business_score: int    # 1-10: Direct revenue value
    future_score: int      # 1-10: LTV indicator
    notes: str = ""

    # Metadata for validation
    time_minutes: float = 5.0  # Estimated time to complete
    difficulty: int = 3        # 1-10 difficulty
    max_daily: int = None      # Daily cap (None = unlimited)


def mode_a_relative_scaling(
    evaluations: List[ActionEvaluation],
    baseline_points: int = 10,
    weights: Dict[str, float] = None
) -> Dict[str, int]:
    """
    Mode A: Relative scaling from baseline action

    Args:
        evaluations: List of evaluated actions
        baseline_points: Points for lowest-scoring action
        weights: Dimension weights (default: C=0.2, E=0.2, B=0.35, F=0.25)

    Returns:
        Dict mapping action names to recommended points
    """
    if weights is None:
        weights = {
            'community': 0.20,
            'quality': 0.20,
            'business': 0.35,
            'future': 0.25
        }

    # Calculate weighted scores
    scores = {}
    for eval in evaluations:
        weighted = (
            weights['community'] * eval.community_score +
            weights['quality'] * eval.quality_score +
            weights['business'] * eval.business_score +
            weights['future'] * eval.future_score
        )
        scores[eval.name] = weighted

    # Scale to baseline
    min_score = min(scores.values())
    recommendations = {}
    for name, score in scores.items():
        ratio = score / min_score
        recommendations[name] = int(baseline_points * ratio)

    return recommendations


def mode_b_economic_anchoring(
    evaluations: List[ActionEvaluation],
    economic_values: Dict[str, float],  # Action -> CLP value
    points_per_clp: float = 0.1  # 1 point = 10 CLP
) -> Dict[str, int]:
    """
    Mode B: Anchor to economic value

    Args:
        evaluations: List of evaluated actions
        economic_values: CLP value per action (revenue, CAC saved, etc.)
        points_per_clp: Conversion rate (default: 1pt = 10 CLP)

    Returns:
        Dict mapping action names to recommended points
    """
    recommendations = {}
    for eval in evaluations:
        if eval.name in economic_values:
            clp_value = economic_values[eval.name]
            recommendations[eval.name] = int(clp_value * points_per_clp)
        else:
            # Fallback to relative scoring if no economic data
            recommendations[eval.name] = 10

    return recommendations


def mode_c_target_based(
    evaluations: List[ActionEvaluation],
    monthly_targets: Dict[str, int],  # Action -> desired count/month
    total_point_budget: int = 100000  # Total points to distribute
) -> Dict[str, int]:
    """
    Mode C: Allocate points to achieve target distribution

    Args:
        evaluations: List of evaluated actions
        monthly_targets: Desired action counts per month
        total_point_budget: Total monthly points to distribute

    Returns:
        Dict mapping action names to recommended points
    """
    # Calculate target point allocation per action
    total_actions = sum(monthly_targets.values())
    recommendations = {}

    for eval in evaluations:
        if eval.name in monthly_targets:
            target_count = monthly_targets[eval.name]
            # Allocate budget proportional to target
            action_budget = total_point_budget * (target_count / total_actions)
            points_per_action = int(action_budget / target_count)
            recommendations[eval.name] = max(1, points_per_action)
        else:
            recommendations[eval.name] = 5  # Default for actions without targets

    return recommendations


def detect_gaming(
    evaluations: List[ActionEvaluation],
    recommendations: Dict[str, int]
) -> List[Tuple[str, str]]:
    """
    Detect gaming vulnerabilities

    Returns:
        List of (vulnerability_type, description) tuples
    """
    issues = []

    # Calculate efficiency: points / (time + difficulty)
    efficiencies = {}
    for eval in evaluations:
        points = recommendations.get(eval.name, 0)
        cost = eval.time_minutes + eval.difficulty
        efficiencies[eval.name] = points / cost if cost > 0 else 0

    # Check for excessive spread
    if efficiencies:
        max_eff = max(efficiencies.values())
        min_eff = min(efficiencies.values())
        if min_eff > 0 and (max_eff / min_eff) > 3:
            issues.append((
                "efficiency_spread",
                f"Efficiency spread {max_eff/min_eff:.1f}x exceeds 3x threshold"
            ))

    # Check for spammable actions
    for eval in evaluations:
        points = recommendations.get(eval.name, 0)
        if eval.max_daily is None and eval.difficulty < 5 and eval.time_minutes < 3:
            daily_potential = int((60 * 8) / eval.time_minutes) * points  # 8hr farming
            issues.append((
                "spam_risk",
                f"{eval.name}: Can farm {daily_potential}pts/day (no cap, low effort)"
            ))

    # Check business priority alignment
    for eval in evaluations:
        if eval.business_score >= 8:  # High business value
            points = recommendations.get(eval.name, 0)
            avg_points = sum(recommendations.values()) / len(recommendations)
            if points < avg_points:
                issues.append((
                    "misaligned_priority",
                    f"{eval.name}: High business value (B={eval.business_score}) but below-average points"
                ))

    return issues


def simulate_rational_actor(
    evaluations: List[ActionEvaluation],
    recommendations: Dict[str, int],
    daily_time_budget_minutes: int = 30
) -> Dict[str, int]:
    """
    Simulate user maximizing points with time constraint

    Returns:
        Dict of action -> predicted daily count
    """
    # Calculate points per minute for each action
    action_efficiency = []
    for eval in evaluations:
        points = recommendations.get(eval.name, 0)
        ppm = points / eval.time_minutes if eval.time_minutes > 0 else 0
        action_efficiency.append((eval.name, ppm, eval.time_minutes, eval.max_daily))

    # Sort by efficiency (greedy algorithm)
    action_efficiency.sort(key=lambda x: x[1], reverse=True)

    # Allocate time budget
    distribution = {}
    remaining_time = daily_time_budget_minutes

    for name, ppm, time_per, max_daily in action_efficiency:
        if remaining_time <= 0:
            break

        # Calculate how many we can do
        max_by_time = int(remaining_time / time_per)
        max_count = max_by_time if max_daily is None else min(max_by_time, max_daily)

        if max_count > 0:
            distribution[name] = max_count
            remaining_time -= max_count * time_per

    return distribution


def export_to_excel(
    evaluations: List[ActionEvaluation],
    recommendations_a: Dict[str, int],
    recommendations_b: Dict[str, int],
    recommendations_c: Dict[str, int],
    gaming_issues: List[Tuple[str, str]],
    output_path: str = "points_economy.xlsx"
):
    """
    Export complete analysis to Excel workbook

    Creates sheets for:
    - Evaluation matrix
    - Mode A/B/C recommendations
    - Gaming validation
    - Scenario comparison
    """
    with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
        # Sheet 1: Evaluation Matrix
        eval_data = []
        for eval in evaluations:
            eval_data.append({
                'Action': eval.name,
                'Community (C)': eval.community_score,
                'Quality (E)': eval.quality_score,
                'Business (B)': eval.business_score,
                'Future (F)': eval.future_score,
                'Time (min)': eval.time_minutes,
                'Difficulty': eval.difficulty,
                'Daily Cap': eval.max_daily or 'Unlimited',
                'Notes': eval.notes
            })
        pd.DataFrame(eval_data).to_excel(writer, sheet_name='Evaluation', index=False)

        # Sheet 2: Recommendations Comparison
        comparison_data = []
        for eval in evaluations:
            comparison_data.append({
                'Action': eval.name,
                'Mode A (Relative)': recommendations_a.get(eval.name, 0),
                'Mode B (Economic)': recommendations_b.get(eval.name, 0),
                'Mode C (Target)': recommendations_c.get(eval.name, 0),
                'Recommended': recommendations_a.get(eval.name, 0)  # Default to Mode A
            })
        pd.DataFrame(comparison_data).to_excel(writer, sheet_name='Recommendations', index=False)

        # Sheet 3: Gaming Issues
        if gaming_issues:
            issues_data = [{'Type': t, 'Description': d} for t, d in gaming_issues]
            pd.DataFrame(issues_data).to_excel(writer, sheet_name='Gaming Risks', index=False)

        # Sheet 4: Rational Actor Simulation
        simulation = simulate_rational_actor(evaluations, recommendations_a)
        sim_data = [{'Action': k, 'Predicted Daily Count': v} for k, v in simulation.items()]
        pd.DataFrame(sim_data).to_excel(writer, sheet_name='User Behavior Sim', index=False)

    print(f"✅ Excel workbook exported to: {output_path}")


# Example usage
if __name__ == "__main__":
    # Example: Zona Cóndores actions
    actions = [
        ActionEvaluation(
            name="ig_comment",
            community_score=5,
            quality_score=3,
            business_score=2,
            future_score=4,
            time_minutes=2,
            difficulty=2,
            max_daily=None,  # No cap - POTENTIAL ISSUE
            notes="Semi-public but easily spammed"
        ),
        ActionEvaluation(
            name="ig_post_hashtag",
            community_score=8,
            quality_score=6,
            business_score=5,
            future_score=6,
            time_minutes=15,
            difficulty=6,
            max_daily=5,
            notes="High reach, requires content creation"
        ),
        ActionEvaluation(
            name="purchase",
            community_score=2,
            quality_score=10,
            business_score=10,
            future_score=8,
            time_minutes=30,
            difficulty=5,
            max_daily=None,
            notes="Direct revenue, verified transaction"
        ),
        ActionEvaluation(
            name="referral",
            community_score=6,
            quality_score=9,
            business_score=7,
            future_score=10,
            time_minutes=60,
            difficulty=8,
            max_daily=10,
            notes="Highest LTV, requires conversion"
        ),
        ActionEvaluation(
            name="poll_response",
            community_score=2,
            quality_score=8,
            business_score=1,
            future_score=2,
            time_minutes=1,
            difficulty=1,
            max_daily=None,
            notes="Easy engagement, no revenue"
        ),
        ActionEvaluation(
            name="trivia_perfect",
            community_score=3,
            quality_score=9,
            business_score=3,
            future_score=5,
            time_minutes=5,
            difficulty=7,
            max_daily=None,
            notes="Quality engagement, knowledge validation"
        ),
    ]

    # Generate recommendations using all 3 modes
    recs_a = mode_a_relative_scaling(actions, baseline_points=10)

    # Mode B example (need economic data)
    economic_data = {
        'ig_comment': 100,      # CLP value of engagement
        'ig_post_hashtag': 500,
        'purchase': 2500,       # Profit margin
        'referral': 15000,      # CAC saved
        'poll_response': 50,
        'trivia_perfect': 200,
    }
    recs_b = mode_b_economic_anchoring(actions, economic_data, points_per_clp=0.1)

    # Mode C example (target distribution)
    targets = {
        'ig_comment': 500,      # Want 500 comments/month
        'ig_post_hashtag': 100,
        'purchase': 50,
        'referral': 20,
        'poll_response': 300,
        'trivia_perfect': 80,
    }
    recs_c = mode_c_target_based(actions, targets, total_point_budget=100000)

    # Validate for gaming
    issues = detect_gaming(actions, recs_a)

    # Print results
    print("\n=== MODE A: Relative Scaling ===")
    for name, pts in sorted(recs_a.items(), key=lambda x: x[1], reverse=True):
        print(f"{name:20s}: {pts:4d} pts")

    print("\n=== MODE B: Economic Anchoring ===")
    for name, pts in sorted(recs_b.items(), key=lambda x: x[1], reverse=True):
        print(f"{name:20s}: {pts:4d} pts")

    print("\n=== MODE C: Target-Based ===")
    for name, pts in sorted(recs_c.items(), key=lambda x: x[1], reverse=True):
        print(f"{name:20s}: {pts:4d} pts")

    print("\n=== GAMING VULNERABILITIES ===")
    for issue_type, description in issues:
        print(f"⚠️  [{issue_type}] {description}")

    print("\n=== RATIONAL ACTOR SIMULATION (30min/day) ===")
    simulation = simulate_rational_actor(actions, recs_a, daily_time_budget_minutes=30)
    for action, count in sorted(simulation.items(), key=lambda x: x[1], reverse=True):
        pts_earned = count * recs_a[action]
        print(f"{action:20s}: {count:3d}x = {pts_earned:5d} pts/day")

    # Export to Excel
    export_to_excel(actions, recs_a, recs_b, recs_c, issues, "zona_condores_points_economy.xlsx")
