#!/usr/bin/env python3
"""
Generate a synthetic mortgage amortization CSV that includes escrow
and optional extra-principal payments.

Example:
    python3 scripts/generate_mortgage_data.py \\
        --start-date 2023-09-06 \\
        --principal 323669.67 \\
        --annual-rate 0.045 \\
        --base-payment 2000 \\
        --escrow 848.18 \\
        --extra-principal 6:500 \\
        --output MortgageData.csv
"""
from __future__ import annotations

import argparse
import csv
import calendar
from datetime import date
from pathlib import Path
from typing import Dict


def parse_extra(values: list[str]) -> Dict[int, float]:
    """Parse CLI entries like '12:500' into {12: 500.0}."""
    extras: Dict[int, float] = {}
    for value in values:
        try:
            payment_str, amount_str = value.split(":", 1)
            payment = int(payment_str)
            amount = float(amount_str)
        except ValueError as exc:  # pragma: no cover - defensive
            raise argparse.ArgumentTypeError(
                f"extra-principal '{value}' must look like payment:amount"
            ) from exc
        if payment <= 0:
            raise argparse.ArgumentTypeError("payment number must be positive")
        extras[payment] = extras.get(payment, 0.0) + amount
    return extras


def compute_base_payment(principal: float, monthly_rate: float, payments: int) -> float:
    """Standard annuity formula."""
    factor = (1 + monthly_rate) ** payments
    return principal * (monthly_rate * factor) / (factor - 1)


def generate_rows(
    principal: float,
    annual_rate: float,
    term_years: int,
    base_payment: float | None,
    escrow: float,
    extra_payments: Dict[int, float],
) -> list[dict[str, float]]:
    payments = term_years * 12
    monthly_rate = annual_rate / 12.0
    if monthly_rate <= 0:
        raise ValueError("Annual rate must be positive to calculate amortization.")
    if base_payment is None:
        base_payment = compute_base_payment(principal, monthly_rate, payments)

    rows = []
    balance = principal
    for payment_num in range(1, payments + 1):
        interest = balance * monthly_rate
        principal_component = base_payment - interest
        if principal_component < 0:
            principal_component = 0.0
        extra_principal = extra_payments.get(payment_num, 0.0)
        applied_extra = min(extra_principal, balance)
        remaining_after_extra = balance - applied_extra
        applied_principal = min(principal_component, remaining_after_extra)
        total_principal = applied_principal + applied_extra
        balance -= total_principal
        if balance < 1e-6:
            balance = 0.0
        rows.append(
            {
                "PaymentNumber": payment_num,
                "ScheduledPrincipal": round(applied_principal, 2),
                "Interest": round(interest, 2),
                "ExtraPrincipal": round(applied_extra, 2),
                "Escrow": round(escrow, 2),
                "RemainingBalance": round(balance, 2),
            }
        )
        if balance <= 0:
            break
    return rows


def parse_date(value: str) -> date:
    try:
        return date.fromisoformat(value)
    except ValueError as exc:  # pragma: no cover - user input
        raise argparse.ArgumentTypeError(
            f"start-date '{value}' must be in YYYY-MM-DD format"
        ) from exc


def add_months(base_date: date, months: int) -> date:
    year = base_date.year + (base_date.month - 1 + months) // 12
    month = (base_date.month - 1 + months) % 12 + 1
    day = min(
        base_date.day,
        calendar.monthrange(year, month)[1],
    )
    return date(year, month, day)


def outstanding_date(payment_date: date) -> date:
    if payment_date.day <= 17:
        day = min(17, calendar.monthrange(payment_date.year, payment_date.month)[1])
        return payment_date.replace(day=day)
    return payment_date


def format_date(value: date) -> str:
    return f"{value.month}/{value.day}/{value.year}"


def format_currency(amount: float) -> str:
    return f"${amount:,.2f}"


def append_transaction(
    entries: list[dict[str, str]], entry_date: date, description: str, amount: float
) -> None:
    amount_rounded = round(amount + 1e-9, 2)
    if amount_rounded <= 0:
        return
    entries.append(
        {
            "Date": format_date(entry_date),
            "Description": description,
            "Amount": format_currency(amount_rounded),
        }
    )


def build_transactions(rows: list[dict[str, float]], start_date: date) -> list[dict[str, str]]:
    entries: list[dict[str, str]] = []
    for index, row in enumerate(rows):
        payment_date = add_months(start_date, index)
        append_transaction(
            entries, payment_date, "Interest Payment Split Out", row["Interest"]
        )
        append_transaction(
            entries,
            payment_date,
            "Principal Payment Split Out",
            row["ScheduledPrincipal"],
        )
        append_transaction(
            entries,
            payment_date,
            "Principal Curtailment",
            row["ExtraPrincipal"],
        )
        append_transaction(entries, payment_date, "Escrow Deposit", row["Escrow"])
        append_transaction(
            entries,
            outstanding_date(payment_date),
            "Outstanding Principal",
            row["RemainingBalance"],
        )
    return entries


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Generate a mortgage amortization CSV for demo dashboards."
    )
    parser.add_argument(
        "--principal",
        type=float,
        default=600_000.0,
        help="Starting loan principal (default: 600000).",
    )
    parser.add_argument(
        "--annual-rate",
        type=float,
        default=0.01251738480743,
        help="Annual interest rate as decimal (default solves for $2k payment).",
    )
    parser.add_argument(
        "--term-years", type=int, default=30, help="Loan length in years (default: 30)."
    )
    parser.add_argument(
        "--base-payment",
        type=float,
        default=None,
        help="Base principal+interest payment. "
        "If omitted, computed from rate/principal/term.",
    )
    parser.add_argument(
        "--escrow",
        type=float,
        default=450.0,
        help="Monthly escrow contribution for taxes/insurance (default: 450).",
    )
    parser.add_argument(
        "--extra-principal",
        action="append",
        default=[],
        metavar="N:AMOUNT",
        help="Add extra principal on payment N (e.g. 12:500). Can be repeated.",
    )
    parser.add_argument(
        "--start-date",
        type=parse_date,
        default=date(2023, 9, 6),
        help="Starting payment date in YYYY-MM-DD format (default: 2023-09-06).",
    )
    default_output = (
        Path(__file__).resolve().parent.parent / "MortgageData.csv"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=default_output,
        help=f"Output CSV path (default: {default_output})",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    extra_map = parse_extra(args.extra_principal)
    amort_rows = generate_rows(
        principal=args.principal,
        annual_rate=args.annual_rate,
        term_years=args.term_years,
        base_payment=args.base_payment,
        escrow=args.escrow,
        extra_payments=extra_map,
    )
    transactions = build_transactions(amort_rows, args.start_date)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="") as f:
        writer = csv.DictWriter(
            f,
            fieldnames=[
                "Date",
                "Description",
                "Amount",
            ],
        )
        writer.writeheader()
        writer.writerows(transactions)
    print(f"Wrote {len(transactions)} rows to {args.output}")


if __name__ == "__main__":
    main()
