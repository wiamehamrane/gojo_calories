"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { apiFetch } from "@/lib/api";
import type { Influencer } from "@/lib/influencer-types";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
  SearchInput,
} from "@/components/ui";

export default function InfluencersPage() {
  const [items, setItems] = useState<Influencer[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    const query = search ? `?search=${encodeURIComponent(search)}` : "";
    apiFetch<{ items: Influencer[] }>(`/admin/influencers${query}`)
      .then((data) => setItems(data.items))
      .finally(() => setLoading(false));
  }, [search]);

  return (
    <div>
      <PageHeader
        title="Influencers"
        description="Manage influencer partners, promo codes, and conversions"
        action={
          <Link href="/influencers/new">
            <Button>Add Influencer</Button>
          </Link>
        }
      />

      <div className="mb-4">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search by name, handle, or email..."
        />
      </div>

      {loading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : (
        <DataTable
          columns={[
            { key: "name", label: "Influencer" },
            { key: "platform", label: "Platform" },
            { key: "codes", label: "Promo Codes" },
            { key: "subs", label: "Subscriptions" },
            { key: "status", label: "Status" },
            { key: "actions", label: "", className: "text-right" },
          ]}
          rows={items.map((inf) => ({
            name: (
              <div>
                <Link
                  href={`/influencers/${inf.id}`}
                  className="font-medium text-primary-dark hover:underline"
                >
                  {inf.display_name}
                </Link>
                <p className="text-xs text-text-secondary">{inf.email}</p>
              </div>
            ),
            platform: inf.platform || "—",
            codes: `${inf.active_codes} active / ${inf.total_codes} total`,
            subs: (
              <span className="font-semibold text-primary-dark">
                {inf.total_redemptions}
              </span>
            ),
            status: (
              <div className="flex gap-1">
                {inf.is_active ? (
                  <Badge variant="success">Active</Badge>
                ) : (
                  <Badge variant="danger">Inactive</Badge>
                )}
                {inf.panel_access && <Badge variant="info">Panel</Badge>}
                {inf.has_paid && <Badge variant="success">Pro</Badge>}
              </div>
            ),
            actions: (
              <Link href={`/influencers/${inf.id}`}>
                <Button variant="secondary">Manage</Button>
              </Link>
            ),
          }))}
          emptyMessage="No influencers yet. Add your first partner."
        />
      )}
    </div>
  );
}
