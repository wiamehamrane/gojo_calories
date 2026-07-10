"use client";

import Link from "next/link";
import { usePaginatedData } from "@/hooks/usePaginatedData";
import type { AdminUser } from "@/lib/types";
import { apiFetch } from "@/lib/api";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
  Pagination,
} from "@/components/ui";

export default function SubscriptionsPage() {
  const { data, page, setPage, loading, refresh } =
    usePaginatedData<AdminUser>("/admin/subscriptions");

  async function revoke(user: AdminUser) {
    await apiFetch(`/admin/subscriptions/${user.id}`, {
      method: "PATCH",
      body: JSON.stringify({ has_paid: false }),
    });
    refresh();
  }

  return (
    <div>
      <PageHeader
        title="Subscriptions"
        description="Manage active and past subscriptions"
      />

      {loading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : (
        <>
          <DataTable
            columns={[
              { key: "email", label: "User" },
              { key: "source", label: "Source" },
              { key: "expires", label: "Expires" },
              { key: "actions", label: "Actions", className: "text-right" },
            ]}
            rows={(data?.items || []).map((user) => ({
              email: (
                <Link
                  href={`/users/${user.id}`}
                  className="font-medium text-primary-dark hover:underline"
                >
                  {user.email}
                </Link>
              ),
              source: (
                <Badge variant="info">
                  {user.subscription_source || "unknown"}
                </Badge>
              ),
              expires: user.subscription_expires_at
                ? new Date(user.subscription_expires_at).toLocaleDateString()
                : "—",
              actions: (
                <div className="flex justify-end">
                  <Button variant="danger" onClick={() => revoke(user)}>
                    Revoke
                  </Button>
                </div>
              ),
            }))}
            emptyMessage="No active subscriptions"
          />
          {data && (
            <Pagination
              page={page}
              totalPages={data.total_pages}
              onPageChange={setPage}
            />
          )}
        </>
      )}
    </div>
  );
}
