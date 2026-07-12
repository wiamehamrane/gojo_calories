"use client";

import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { apiFetch, ApiError } from "@/lib/api";
import type { InfluencerDetail, PromoPlatform } from "@/lib/influencer-types";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
} from "@/components/ui";

const GRANT_PLANS = [
  { value: "monthly", label: "Monthly Pro" },
  { value: "six_month", label: "6-month Pro" },
  { value: "yearly", label: "Yearly Pro" },
  { value: "lifetime", label: "Lifetime Pro" },
  { value: "trial_7d", label: "7-day trial" },
];

const STORE_PLANS = [
  { value: "monthly", label: "Monthly Pro" },
  { value: "six_month", label: "6-month Pro" },
  { value: "yearly", label: "Yearly Pro" },
];

const PLATFORM_LABEL: Record<PromoPlatform, string> = {
  internal: "Internal (free grant)",
  apple: "Apple offer code",
  google: "Google Play promo",
};

export default function InfluencerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [data, setData] = useState<InfluencerDetail | null>(null);
  const [error, setError] = useState("");
  const [promoForm, setPromoForm] = useState({
    platform: "internal" as PromoPlatform,
    code: "",
    plan_type: "monthly",
    max_redemptions: "",
    notes: "",
  });
  const [appleBatch, setAppleBatch] = useState({
    plan_type: "monthly",
    number_of_codes: "10",
    expiration_date: "",
  });
  const [creating, setCreating] = useState(false);
  const [batchCreating, setBatchCreating] = useState(false);

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
          platform: promoForm.platform,
          code: promoForm.code.trim() || undefined,
          plan_type: promoForm.plan_type,
          max_redemptions: promoForm.max_redemptions
            ? parseInt(promoForm.max_redemptions, 10)
            : null,
          notes: promoForm.notes.trim() || undefined,
        }),
      });
      setPromoForm({
        platform: promoForm.platform,
        code: "",
        plan_type: promoForm.plan_type,
        max_redemptions: "",
        notes: "",
      });
      load();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create code");
    } finally {
      setCreating(false);
    }
  }

  async function createAppleBatch(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setBatchCreating(true);
    try {
      const result = await apiFetch<{ generated_count: number }>(
        `/admin/influencers/${id}/promo-codes/apple-batch`,
        {
          method: "POST",
          body: JSON.stringify({
            plan_type: appleBatch.plan_type,
            number_of_codes: parseInt(appleBatch.number_of_codes, 10),
            expiration_date: appleBatch.expiration_date,
          }),
        }
      );
      setError("");
      alert(`Generated ${result.generated_count} Apple offer codes`);
      load();
    } catch (err) {
      setError(
        err instanceof ApiError ? err.message : "Apple batch generation failed"
      );
    } finally {
      setBatchCreating(false);
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

  const planOptions =
    promoForm.platform === "internal" ? GRANT_PLANS : STORE_PLANS;

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

        <div className="rounded-[20px] border border-border bg-surface p-6 shadow-sm">
          <h2 className="mb-2 text-lg font-bold">Create promo code</h2>
          <p className="mb-4 text-sm text-text-secondary">
            Hybrid promos: internal codes grant free Pro instantly; Apple and
            Google codes must be created in the store first, then registered
            here for attribution.
          </p>
          {error && (
            <p className="mb-3 rounded-2xl bg-red-50 px-4 py-2 text-sm text-danger">
              {error}
            </p>
          )}
          <form onSubmit={createPromo} className="space-y-3">
            <select
              value={promoForm.platform}
              onChange={(e) =>
                setPromoForm((f) => ({
                  ...f,
                  platform: e.target.value as PromoPlatform,
                  plan_type: "monthly",
                  code: "",
                }))
              }
              className={`${inputClass} w-full`}
            >
              <option value="internal">Internal — instant free grant</option>
              <option value="apple">Apple — offer / promo code</option>
              <option value="google">Google Play — promo code</option>
            </select>

            {promoForm.platform === "internal" ? (
              <p className="text-xs text-text-secondary">
                Code is auto-generated if left blank. User gets Pro immediately
                in the app.
              </p>
            ) : promoForm.platform === "apple" ? (
              <p className="text-xs text-text-secondary">
                Create the code in App Store Connect → Subscriptions → Offer
                Codes, then paste the exact code below.
              </p>
            ) : (
              <p className="text-xs text-text-secondary">
                Create the promo in Google Play Console → Monetization → Promo
                codes, then paste the exact code below.
              </p>
            )}

            <input
              value={promoForm.code}
              onChange={(e) =>
                setPromoForm((f) => ({
                  ...f,
                  code: e.target.value.toUpperCase(),
                }))
              }
              placeholder={
                promoForm.platform === "internal"
                  ? "Custom code (auto-generated if empty)"
                  : "Exact code from App Store / Play Console"
              }
              required={promoForm.platform !== "internal"}
              className={`${inputClass} w-full`}
            />
            <select
              value={promoForm.plan_type}
              onChange={(e) =>
                setPromoForm((f) => ({ ...f, plan_type: e.target.value }))
              }
              className={`${inputClass} w-full`}
            >
              {planOptions.map((p) => (
                <option key={p.value} value={p.value}>
                  {promoForm.platform === "internal"
                    ? `Grants: ${p.label}`
                    : `Store plan: ${p.label}`}
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
            <input
              value={promoForm.notes}
              onChange={(e) =>
                setPromoForm((f) => ({ ...f, notes: e.target.value }))
              }
              placeholder="Notes (optional)"
              className={`${inputClass} w-full`}
            />
            <Button type="submit" disabled={creating}>
              {creating ? "Creating..." : "Register promo code"}
            </Button>
          </form>

          {promoForm.platform === "apple" && (
            <div className="mt-6 border-t border-border pt-6">
              <h3 className="mb-2 text-sm font-bold">
                Or generate Apple batch (ASC API)
              </h3>
              <p className="mb-3 text-xs text-text-secondary">
                Requires APPLE_ASC_* env vars on the backend. Codes appear in
                App Store Connect and are registered automatically.
              </p>
              <form onSubmit={createAppleBatch} className="space-y-3">
                <select
                  value={appleBatch.plan_type}
                  onChange={(e) =>
                    setAppleBatch((f) => ({ ...f, plan_type: e.target.value }))
                  }
                  className={`${inputClass} w-full`}
                >
                  {STORE_PLANS.map((p) => (
                    <option key={p.value} value={p.value}>
                      {p.label}
                    </option>
                  ))}
                </select>
                <input
                  type="number"
                  min={1}
                  max={500}
                  value={appleBatch.number_of_codes}
                  onChange={(e) =>
                    setAppleBatch((f) => ({
                      ...f,
                      number_of_codes: e.target.value,
                    }))
                  }
                  placeholder="Number of codes"
                  className={`${inputClass} w-full`}
                />
                <input
                  type="date"
                  value={appleBatch.expiration_date}
                  onChange={(e) =>
                    setAppleBatch((f) => ({
                      ...f,
                      expiration_date: e.target.value,
                    }))
                  }
                  required
                  className={`${inputClass} w-full`}
                />
                <Button type="submit" disabled={batchCreating} variant="secondary">
                  {batchCreating ? "Generating..." : "Generate Apple batch"}
                </Button>
              </form>
            </div>
          )}
        </div>
      </div>

      <h2 className="mb-3 text-lg font-bold">Promo codes</h2>
      <DataTable
        columns={[
          { key: "code", label: "Code" },
          { key: "platform", label: "Type" },
          { key: "plan", label: "Plan" },
          { key: "usage", label: "Redemptions" },
          { key: "status", label: "Status" },
          { key: "actions", label: "", className: "text-right" },
        ]}
        rows={(data.promo_codes || []).map((p) => ({
          code: (
            <div>
              <span className="font-mono font-bold">{p.code}</span>
              {p.redeem_url && (
                <a
                  href={p.redeem_url}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-1 block text-xs text-primary"
                >
                  Play redeem link
                </a>
              )}
            </div>
          ),
          platform: (
            <Badge variant={p.platform === "internal" ? "default" : "success"}>
              {PLATFORM_LABEL[p.platform] || p.platform}
            </Badge>
          ),
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
