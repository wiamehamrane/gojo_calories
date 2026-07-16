"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { apiFetch } from "@/lib/api";
import type { InfluencerDetail } from "@/lib/influencer-types";
import { Badge, Button, PageHeader } from "@/components/ui";

const GRANT_PLANS = [
  { value: "monthly", label: "Monthly Pro" },
  { value: "six_month", label: "6-month Pro" },
  { value: "yearly", label: "Yearly Pro" },
  { value: "lifetime", label: "Lifetime Pro" },
  { value: "trial_7d", label: "7-day trial" },
];

export default function InfluencerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [data, setData] = useState<InfluencerDetail | null>(null);

  function load() {
    apiFetch<InfluencerDetail>(`/admin/influencers/${id}`).then(setData);
  }

  useEffect(() => {
    load();
  }, [id]);

  async function grantPlan(plan_type: string) {
    await apiFetch(`/admin/influencers/${id}/grant-subscription`, {
      method: "POST",
      body: JSON.stringify({ plan_type }),
    });
    load();
  }

  async function revokeSub() {
    await apiFetch(`/admin/influencers/${id}/revoke-subscription`, {
      method: "POST",
    });
    load();
  }

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
        title={data.display_name}
        description={`${data.email}${data.handle ? ` · ${data.handle}` : ""}`}
      />

      <div className="mb-6 grid gap-4 md:grid-cols-3">
        {[
          {
            label: "Commission",
            value: data.commission_rate ? `${data.commission_rate}%` : "—",
          },
          {
            label: "Panel access",
            value: data.panel_access ? "Yes" : "No",
          },
          {
            label: "Status",
            value: data.is_active ? "Active" : "Inactive",
          },
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

      <div className="rounded-[20px] border border-border bg-surface p-6 shadow-sm">
        <h2 className="mb-4 text-lg font-bold">Influencer subscription</h2>
        <div className="mb-4 flex flex-wrap gap-2">
          {data.has_paid ? (
            <Badge variant="success">
              {data.subscription_source || "Pro"} — expires{" "}
              {data.subscription_expires_at
                ? new Date(data.subscription_expires_at).toLocaleDateString()
                : "never"}
            </Badge>
          ) : (
            <Badge>No active subscription</Badge>
          )}
        </div>
        <div className="flex flex-wrap gap-2">
          {GRANT_PLANS.map((p) => (
            <Button key={p.value} onClick={() => grantPlan(p.value)}>
              Grant {p.label}
            </Button>
          ))}
          {data.has_paid && (
            <Button variant="danger" onClick={revokeSub}>
              Revoke
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}
