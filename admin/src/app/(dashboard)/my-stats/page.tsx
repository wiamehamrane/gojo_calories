"use client";

import { useEffect, useState } from "react";
import { apiFetch } from "@/lib/api";
import type { InfluencerDetail } from "@/lib/influencer-types";
import { Badge, PageHeader } from "@/components/ui";

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
        description="Your influencer partner profile"
      />

      <div className="mb-6 grid gap-4 md:grid-cols-3">
        {[
          {
            label: "Your subscription",
            value: data.has_paid ? "Pro" : "None",
          },
          {
            label: "Panel access",
            value: data.panel_access ? "Enabled" : "Disabled",
          },
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

      <div className="rounded-[20px] border border-border bg-surface p-6 shadow-sm">
        <h2 className="mb-3 text-lg font-bold">Profile</h2>
        <dl className="space-y-2 text-sm">
          <div className="flex justify-between gap-4">
            <dt className="text-text-secondary">Email</dt>
            <dd className="font-medium text-text-primary">{data.email || "—"}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-text-secondary">Handle</dt>
            <dd className="font-medium text-text-primary">{data.handle || "—"}</dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-text-secondary">Platform</dt>
            <dd className="font-medium text-text-primary">
              {data.platform || "—"}
            </dd>
          </div>
          <div className="flex justify-between gap-4">
            <dt className="text-text-secondary">Status</dt>
            <dd>
              {data.is_active ? (
                <Badge variant="success">Active</Badge>
              ) : (
                <Badge variant="danger">Inactive</Badge>
              )}
            </dd>
          </div>
        </dl>
      </div>
    </div>
  );
}
