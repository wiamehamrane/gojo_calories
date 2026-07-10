"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { apiFetch, ApiError } from "@/lib/api";
import type { InfluencerDetail } from "@/lib/influencer-types";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
} from "@/components/ui";

const PLANS = [
  { value: "monthly", label: "Monthly Pro" },
  { value: "yearly", label: "Yearly Pro" },
  { value: "lifetime", label: "Lifetime Pro" },
  { value: "trial_7d", label: "7-day trial" },
];

export default function InfluencerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [data, setData] = useState<InfluencerDetail | null>(null);
  const [error, setError] = useState("");
  const [promoForm, setPromoForm] = useState({
    code: "",
    plan_type: "monthly",
    max_redemptions: "",
  });
  const [creating, setCreating] = useState(false);

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

  async function createPromo(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setCreating(true);
    try {
      await apiFetch(`/admin/influencers/${id}/promo-codes`, {
        method: "POST",
        body: JSON.stringify({
          code: promoForm.code.trim() || undefined,
          plan_type: promoForm.plan_type,
          max_redemptions: promoForm.max_redemptions
            ? parseInt(promoForm.max_redemptions, 10)
            : null,
        }),
      });
      setPromoForm({ code: "", plan_type: "monthly", max_redemptions: "" });
      load();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create code");
    } finally {
      setCreating(false);
    }
  }

  async function togglePromo(promoId: string, is_active: boolean) {
    await apiFetch(`/admin/influencers/${id}/promo-codes/${promoId}`, {
      method: "PATCH",
      body: JSON.stringify({ is_active }),
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

  const inputClass =
    "rounded-2xl border border-border bg-background px-4 py-2.5 text-sm outline-none focus:border-primary";

  return (
    <div>
      <PageHeader
        title={data.display_name}
        description={`${data.email}${data.handle ? ` · ${data.handle}` : ""}`}
      />

      <div className="mb-6 grid gap-4 md:grid-cols-4">
        {[
          { label: "Total subscriptions", value: data.total_redemptions },
          { label: "Active codes", value: data.active_codes },
          { label: "Total codes", value: data.total_codes },
          {
            label: "Commission",
            value: data.commission_rate ? `${data.commission_rate}%` : "—",
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

      <div className="mb-6 grid gap-6 lg:grid-cols-2">
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
            {PLANS.map((p) => (
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

        <div className="rounded-[20px] border border-border bg-surface p-6 shadow-sm">
          <h2 className="mb-4 text-lg font-bold">Create promo code</h2>
          {error && (
            <p className="mb-3 rounded-2xl bg-red-50 px-4 py-2 text-sm text-danger">
              {error}
            </p>
          )}
          <form onSubmit={createPromo} className="space-y-3">
            <input
              value={promoForm.code}
              onChange={(e) =>
                setPromoForm((f) => ({ ...f, code: e.target.value.toUpperCase() }))
              }
              placeholder="Custom code (auto-generated if empty)"
              className={`${inputClass} w-full`}
            />
            <select
              value={promoForm.plan_type}
              onChange={(e) =>
                setPromoForm((f) => ({ ...f, plan_type: e.target.value }))
              }
              className={`${inputClass} w-full`}
            >
              {PLANS.map((p) => (
                <option key={p.value} value={p.value}>
                  Grants: {p.label}
                </option>
              ))}
            </select>
            <input
              type="number"
              value={promoForm.max_redemptions}
              onChange={(e) =>
                setPromoForm((f) => ({ ...f, max_redemptions: e.target.value }))
              }
              placeholder="Max redemptions (unlimited if empty)"
              className={`${inputClass} w-full`}
            />
            <Button type="submit" disabled={creating}>
              {creating ? "Creating..." : "Create Promo Code"}
            </Button>
          </form>
        </div>
      </div>

      <h2 className="mb-3 text-lg font-bold">Promo codes</h2>
      <DataTable
        columns={[
          { key: "code", label: "Code" },
          { key: "plan", label: "Grants" },
          { key: "usage", label: "Redemptions" },
          { key: "status", label: "Status" },
          { key: "actions", label: "", className: "text-right" },
        ]}
        rows={(data.promo_codes || []).map((p) => ({
          code: <span className="font-mono font-bold">{p.code}</span>,
          plan: p.plan_type,
          usage: `${p.redemption_count}${p.max_redemptions ? ` / ${p.max_redemptions}` : ""}`,
          status: (
            <Badge variant={p.is_active ? "success" : "default"}>
              {p.is_active ? "Active" : "Inactive"}
            </Badge>
          ),
          actions: (
            <Button
              variant={p.is_active ? "danger" : "secondary"}
              onClick={() => togglePromo(p.id, !p.is_active)}
            >
              {p.is_active ? "Deactivate" : "Activate"}
            </Button>
          ),
        }))}
        emptyMessage="No promo codes yet"
      />

      <h2 className="mb-3 mt-8 text-lg font-bold">Recent subscriptions via promo</h2>
      <DataTable
        columns={[
          { key: "email", label: "User" },
          { key: "code", label: "Code" },
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
        emptyMessage="No redemptions yet"
      />
    </div>
  );
}
