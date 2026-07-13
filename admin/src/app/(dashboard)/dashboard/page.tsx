"use client";

import { useEffect, useState } from "react";
import {
  Users,
  CreditCard,
  Calendar,
  Gift,
  Megaphone,
} from "lucide-react";
import { apiFetch } from "@/lib/api";
import type { DashboardStats } from "@/lib/types";
import { StatsCard } from "@/components/StatsCard";
import { PageHeader } from "@/components/ui";

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);

  useEffect(() => {
    apiFetch<DashboardStats>("/admin/dashboard").then(setStats);
  }, []);

  if (!stats) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Dashboard"
        description="Overview of your GojoCalories platform"
      />

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
        <StatsCard label="Total Users" value={stats.total_users} icon={Users} />
        <StatsCard
          label="Paid Subscribers"
          value={stats.paid_users}
          icon={CreditCard}
          accent="#E8F5E9"
        />
        <StatsCard
          label="Verified Users"
          value={stats.verified_users}
          icon={Users}
          accent="#FFF3E0"
        />
        <StatsCard
          label="Events"
          value={stats.total_events}
          icon={Calendar}
        />
        <StatsCard
          label="Pending Withdrawals"
          value={stats.pending_withdrawals}
          icon={Gift}
          accent="#FFEBEE"
        />
        <StatsCard
          label="Banned Users"
          value={stats.banned_users}
          icon={Users}
          accent="#FFEBEE"
        />
        <StatsCard
          label="Influencers"
          value={stats.active_influencers}
          icon={Megaphone}
        />
        <StatsCard
          label="Promo Subscriptions"
          value={stats.total_promo_redemptions}
          icon={Gift}
          accent="#E8F5E9"
        />
      </div>

      <div className="mt-8 rounded-[20px] border border-border bg-surface p-6 shadow-sm">
        <h2 className="mb-4 text-lg font-bold text-text-primary">
          Subscription Breakdown
        </h2>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
          {Object.entries(stats.subscription_breakdown).map(([source, count]) => (
            <div
              key={source}
              className="rounded-2xl bg-surface-muted px-4 py-3 text-center"
            >
              <p className="text-2xl font-bold text-text-primary">{count}</p>
              <p className="text-sm capitalize text-text-secondary">{source}</p>
            </div>
          ))}
          {Object.keys(stats.subscription_breakdown).length === 0 && (
            <p className="text-sm text-text-secondary">No active subscriptions</p>
          )}
        </div>
      </div>
    </div>
  );
}
