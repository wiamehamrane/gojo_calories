"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { usePaginatedData } from "@/hooks/usePaginatedData";
import type { AdminUser } from "@/lib/types";
import {
  Badge,
  Button,
  DataTable,
  PageHeader,
  Pagination,
  SearchInput,
} from "@/components/ui";
import {
  Modal,
  UserForm,
  UserFormActions,
  emptyUserForm,
  formDataToPayload,
} from "@/components/UserForm";
import { apiFetch, ApiError } from "@/lib/api";

export default function UsersPage() {
  const router = useRouter();
  const [search, setSearch] = useState("");
  const [filter, setFilter] = useState<"all" | "paid" | "banned">("all");
  const [showCreate, setShowCreate] = useState(false);
  const [form, setForm] = useState(emptyUserForm());
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const params = {
    search: search || undefined,
    has_paid: filter === "paid" ? true : undefined,
    is_banned: filter === "banned" ? true : undefined,
  };
  const { data, page, setPage, loading, refresh } =
    usePaginatedData<AdminUser>("/admin/users", params);

  async function toggleBan(user: AdminUser) {
    await apiFetch(`/admin/users/${user.id}`, {
      method: "PATCH",
      body: JSON.stringify({ is_banned: !user.is_banned }),
    });
    refresh();
  }

  async function createUser() {
    setError("");
    setSaving(true);
    try {
      const created = await apiFetch<{ id: string }>("/admin/users", {
        method: "POST",
        body: JSON.stringify(formDataToPayload(form, "create")),
      });
      setShowCreate(false);
      setForm(emptyUserForm());
      refresh();
      router.push(`/users/${created.id}`);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to create user");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Users"
        description="Manage all registered users"
        action={<Button onClick={() => setShowCreate(true)}>Add User</Button>}
      />

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <SearchInput
          value={search}
          onChange={setSearch}
          placeholder="Search by email or name..."
        />
        <select
          value={filter}
          onChange={(e) => setFilter(e.target.value as typeof filter)}
          className="rounded-2xl border border-border bg-surface px-4 py-2.5 text-sm"
        >
          <option value="all">All users</option>
          <option value="paid">Paid only</option>
          <option value="banned">Banned only</option>
        </select>
      </div>

      {loading ? (
        <div className="flex h-40 items-center justify-center">
          <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
        </div>
      ) : (
        <>
          <DataTable
            columns={[
              { key: "email", label: "Email" },
              { key: "name", label: "Name" },
              { key: "status", label: "Status" },
              { key: "subscription", label: "Subscription" },
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
              name: user.name || "—",
              status: (
                <div className="flex gap-1">
                  {user.is_email_verified && (
                    <Badge variant="success">Verified</Badge>
                  )}
                  {user.is_banned && <Badge variant="danger">Banned</Badge>}
                  {user.is_admin && <Badge variant="info">Admin</Badge>}
                </div>
              ),
              subscription: user.has_paid ? (
                <Badge variant="success">
                  {user.subscription_source || "paid"}
                </Badge>
              ) : (
                <Badge>Free</Badge>
              ),
              actions: (
                <div className="flex justify-end gap-2">
                  <Link href={`/users/${user.id}`}>
                    <Button variant="secondary">Edit</Button>
                  </Link>
                  <Button
                    variant={user.is_banned ? "secondary" : "danger"}
                    onClick={() => toggleBan(user)}
                  >
                    {user.is_banned ? "Unban" : "Ban"}
                  </Button>
                </div>
              ),
            }))}
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

      <Modal
        title="Add User"
        open={showCreate}
        onClose={() => {
          setShowCreate(false);
          setError("");
          setForm(emptyUserForm());
        }}
        footer={
          <UserFormActions
            submitLabel="Create User"
            loading={saving}
            onCancel={() => setShowCreate(false)}
            onSubmit={createUser}
          />
        }
      >
        {error && (
          <p className="mb-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-danger">
            {error}
          </p>
        )}
        <UserForm data={form} onChange={setForm} mode="create" />
      </Modal>
    </div>
  );
}
