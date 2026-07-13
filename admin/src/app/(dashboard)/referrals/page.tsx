"use client";

import { usePaginatedData } from "@/hooks/usePaginatedData";
import type { ReferralItem, WithdrawalItem } from "@/lib/types";
import { apiFetch } from "@/lib/api";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
  Pagination,
} from "@/components/ui";

export default function ReferralsPage() {
  const referrals = usePaginatedData<ReferralItem>("/admin/referrals");
  const withdrawals = usePaginatedData<WithdrawalItem>("/admin/withdrawals");

  async function markPaid(id: string) {
    await apiFetch(`/admin/withdrawals/${id}`, {
      method: "PATCH",
      body: JSON.stringify({ status: "paid" }),
    });
    withdrawals.refresh();
  }

  return (
    <div>
      <PageHeader
        title="Referrals & Withdrawals"
        description="Track referral earnings and payout requests"
      />

      <h2 className="mb-3 text-lg font-bold">Pending Withdrawals</h2>
      {withdrawals.loading ? (
        <div className="mb-8 flex h-20 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : (
        <div className="mb-10">
          <DataTable
            columns={[
              { key: "user", label: "User" },
              { key: "amount", label: "Amount" },
              { key: "method", label: "Method" },
              { key: "status", label: "Status" },
              { key: "date", label: "Date" },
              { key: "actions", label: "", className: "text-right" },
            ]}
            rows={(withdrawals.data?.items || []).map((w) => ({
              user: w.user_email || w.user_id,
              amount: `$${w.amount.toFixed(2)}`,
              method: w.method,
              status: (
                <Badge variant={w.status === "paid" ? "success" : "warning"}>
                  {w.status}
                </Badge>
              ),
              date: w.created_at
                ? new Date(w.created_at).toLocaleDateString()
                : "—",
              actions:
                w.status === "pending" ? (
                  <Button onClick={() => markPaid(w.id)}>Mark Paid</Button>
                ) : null,
            }))}
            emptyMessage="No withdrawal requests"
          />
          {withdrawals.data && (
            <Pagination
              page={withdrawals.page}
              totalPages={withdrawals.data.total_pages}
              onPageChange={withdrawals.setPage}
            />
          )}
        </div>
      )}

      <h2 className="mb-3 text-lg font-bold">Referral History</h2>
      {referrals.loading ? (
        <div className="flex h-20 items-center justify-center">
          <div className="h-6 w-6 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : (
        <>
          <DataTable
            columns={[
              { key: "referrer", label: "Referrer" },
              { key: "referred", label: "Referred" },
              { key: "amount", label: "Amount" },
              { key: "date", label: "Date" },
            ]}
            rows={(referrals.data?.items || []).map((r) => ({
              referrer: r.referrer_email || r.referrer_id,
              referred: r.referred_email || r.referred_user_id,
              amount: `$${r.amount.toFixed(2)}`,
              date: r.created_at
                ? new Date(r.created_at).toLocaleDateString()
                : "—",
            }))}
          />
          {referrals.data && (
            <Pagination
              page={referrals.page}
              totalPages={referrals.data.total_pages}
              onPageChange={referrals.setPage}
            />
          )}
        </>
      )}
    </div>
  );
}
