"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Sparkles } from "lucide-react";
import { apiFetch, ApiError } from "@/lib/api";
import { Button } from "@/components/ui";
import {
  FormField,
  FormSection,
  PlanOption,
  PlatformChip,
  PremiumPageHero,
  ToggleSwitch,
  premiumInputClass,
} from "@/components/PremiumForm";

const PLANS = [
  { value: "", label: "None", description: "No subscription on create" },
  { value: "trial_7d", label: "7-day trial", description: "Free Pro for 7 days" },
  { value: "monthly", label: "Monthly Pro", description: "30 days of full access" },
  { value: "yearly", label: "Yearly Pro", description: "365 days of full access" },
  { value: "lifetime", label: "Lifetime Pro", description: "Never expires" },
];

const PLATFORMS = ["instagram", "tiktok", "youtube", "twitter", "other"];

export default function NewInfluencerPage() {
  const router = useRouter();
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    email: "",
    password: "",
    name: "",
    display_name: "",
    handle: "",
    platform: "instagram",
    notes: "",
    commission_rate: "",
    panel_access: true,
    grant_plan: "",
  });

  function setField(key: string, value: string | boolean) {
    setForm((f) => ({ ...f, [key]: value }));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const created = await apiFetch<{ id: string }>("/admin/influencers", {
        method: "POST",
        body: JSON.stringify({
          email: form.email,
          password: form.password,
          name: form.name || form.display_name,
          display_name: form.display_name,
          handle: form.handle || null,
          platform: form.platform,
          notes: form.notes || null,
          commission_rate: form.commission_rate
            ? parseFloat(form.commission_rate)
            : null,
          panel_access: form.panel_access,
          grant_plan: form.grant_plan || null,
        }),
      });
      router.push(`/influencers/${created.id}`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create");
    } finally {
      setLoading(false);
    }
  }

  const selectedPlan = PLANS.find((p) => p.value === form.grant_plan) ?? PLANS[0];

  return (
    <div className="mx-auto max-w-4xl">
      <PremiumPageHero
        backHref="/influencers"
        backLabel="Back to influencers"
        title="Add Influencer"
        description="Onboard a new partner with panel access and an optional Pro subscription."
      />

      <form onSubmit={handleSubmit} className="space-y-5">
        {error && (
          <div className="rounded-2xl border border-red-100 bg-red-50/80 px-4 py-3 text-sm text-danger">
            {error}
          </div>
        )}

        <FormSection
          title="Profile"
          description="Public-facing details for this partner."
        >
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Display name" required className="md:col-span-2">
              <input
                required
                value={form.display_name}
                onChange={(e) => setField("display_name", e.target.value)}
                placeholder="Sarah Fitness"
                className={premiumInputClass}
              />
            </FormField>
            <FormField label="Handle" hint="Their social username">
              <input
                value={form.handle}
                onChange={(e) => setField("handle", e.target.value)}
                placeholder="@username"
                className={premiumInputClass}
              />
            </FormField>
            <FormField label="Platform">
              <div className="flex flex-wrap gap-2 pt-1">
                {PLATFORMS.map((p) => (
                  <PlatformChip
                    key={p}
                    label={p}
                    selected={form.platform === p}
                    onSelect={() => setField("platform", p)}
                  />
                ))}
              </div>
            </FormField>
          </div>
        </FormSection>

        <FormSection
          title="Account credentials"
          description="Used to sign in to the influencer panel."
        >
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="Email" required>
              <input
                type="email"
                required
                value={form.email}
                onChange={(e) => setField("email", e.target.value)}
                placeholder="partner@email.com"
                className={premiumInputClass}
              />
            </FormField>
            <FormField label="Password" required>
              <input
                type="password"
                required
                value={form.password}
                onChange={(e) => setField("password", e.target.value)}
                placeholder="••••••••"
                className={premiumInputClass}
              />
            </FormField>
          </div>
        </FormSection>

        <FormSection
          title="Partnership"
          description="Subscription grant and commission settings."
        >
          <FormField label="Grant subscription on create" className="mb-4">
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              {PLANS.map((plan) => (
                <PlanOption
                  key={plan.value || "none"}
                  label={plan.label}
                  description={plan.description}
                  selected={form.grant_plan === plan.value}
                  onSelect={() => setField("grant_plan", plan.value)}
                />
              ))}
            </div>
          </FormField>
          <FormField label="Commission rate" hint="Optional — for future payouts">
            <div className="relative">
              <input
                type="number"
                step="0.1"
                min="0"
                max="100"
                value={form.commission_rate}
                onChange={(e) => setField("commission_rate", e.target.value)}
                placeholder="10"
                className={`${premiumInputClass} pr-10`}
              />
              <span className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-sm text-text-secondary">
                %
              </span>
            </div>
          </FormField>
        </FormSection>

        <FormSection title="Access & notes">
          <div className="space-y-4">
            <ToggleSwitch
              checked={form.panel_access}
              onChange={(v) => setField("panel_access", v)}
              label="Panel access"
              description="Allow login at admin.gojocalories.com to view their partner profile"
            />
            <FormField label="Internal notes">
              <textarea
                value={form.notes}
                onChange={(e) => setField("notes", e.target.value)}
                rows={3}
                placeholder="Contract details, special terms, contact info..."
                className={`${premiumInputClass} resize-none`}
              />
            </FormField>
          </div>
        </FormSection>

        {/* Summary + actions */}
        <div className="sticky bottom-0 -mx-2 rounded-[24px] border border-border/80 bg-surface/95 px-6 py-4 shadow-[0_-4px_24px_rgba(0,0,0,0.06)] backdrop-blur-md">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-start gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-surface-teal-light text-primary-dark">
                <Sparkles size={18} />
              </div>
              <div>
                <p className="text-sm font-semibold text-text-primary">
                  {form.display_name || "New influencer"}
                </p>
                <p className="text-xs text-text-secondary">
                  {form.platform} · {selectedPlan.label}
                  {form.panel_access ? " · Panel enabled" : ""}
                </p>
              </div>
            </div>
            <div className="flex gap-2 sm:shrink-0">
              <Button
                variant="secondary"
                onClick={() => router.push("/influencers")}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={loading}>
                {loading ? "Creating..." : "Create Influencer"}
              </Button>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
