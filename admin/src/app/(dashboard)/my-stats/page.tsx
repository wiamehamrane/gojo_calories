"use client";

import { useEffect, useState } from "react";
import { apiFetch } from "@/lib/api";
import type { InfluencerDetail } from "@/lib/influencer-types";
import { Badge, DataTable, PageHeader } from "@/components/ui";

export default function MyStatsPage() {
  const [data, setData] = useState<InfluencerDetail | null>(null);

  useEffect(() => {
    apiFetch<InfluencerDetail>("/admin/influencer/me").then(setData);
  }, []);

  if (!data) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title={`Welcome, ${data.display_name}`}
        description="Track your promo codes and app subscriptions"
      />

      <div className="mb-6 grid gap-4 md:grid-cols-3">
        {[
          { label: "Total subscriptions", value: data.total_redemptions },
          { label: "Active promo codes", value: data.active_codes },
          { label: "Your subscription", value: data.has_paid ? "Pro" : "None" },
        ].map((stat) => (
          <div
            key={stat.label}
            className="rounded-[20px] border border-border bg-surface p-4 shadow-sm"
          >
            <p className="text-sm text-text-secondary">{stat.label}</p>
            <p className="mt-1 text-2xl font-bold text-text-primary">
              {stat.value}
            </p>
          </div>
        ))}
      </div>

      <h2 className="mb-3 text-lg font-bold">Your promo codes</h2>
      <DataTable
        columns={[
          { key: "code", label: "Code" },
          { key: "plan", label: "Grants" },
          { key: "usage", label: "Used" },
          { key: "status", label: "Status" },
        ]}
        rows={(data.promo_codes || []).map((p) => ({
          code: <span className="font-mono font-bold text-primary-dark">{p.code}</span>,
          plan: p.plan_type,
          usage: `${p.redemption_count}${p.max_redemptions ? ` / ${p.max_redemptions}` : ""}`,
          status: (
            <Badge variant={p.is_active ? "success" : "default"}>
              {p.is_active ? "Active" : "Inactive"}
            </Badge>
          ),
        }))}
        emptyMessage="No promo codes assigned yet"
      />

      <h2 className="mb-3 mt-8 text-lg font-bold">People who subscribed</h2>
      <DataTable
        columns={[
          { key: "email", label: "User" },
          { key: "code", label: "Code used" },
          { key: "plan", label: "Plan" },
          { key: "date", label: "Date" },
        ]}
        rows={(data.recent_redemptions || []).map((r) => ({
          email: r.user_email || "—",
          code: r.code || "—",
          plan: r.plan_granted,
          date: r.redeemed_at
            ? new Date(r.redeemed_at).toLocaleDateString()
            : "—",
        }))}
        emptyMessage="No subscriptions yet — share your promo codes!"
      />
    </div>
  );
}
