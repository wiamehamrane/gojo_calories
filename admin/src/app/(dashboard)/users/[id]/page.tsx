"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { apiFetch, ApiError } from "@/lib/api";
import type { UserDetail } from "@/lib/types";
import { Badge, Button, PageHeader } from "@/components/ui";
import {
  UserForm,
  UserFormActions,
  formDataToPayload,
  userToFormData,
  type UserFormData,
} from "@/components/UserForm";

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [user, setUser] = useState<UserDetail | null>(null);
  const [form, setForm] = useState<UserFormData | null>(null);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  useEffect(() => {
    apiFetch<UserDetail>(`/admin/users/${id}`).then((data) => {
      setUser(data);
      setForm(userToFormData(data));
    });
  }, [id]);

  async function saveUser() {
    if (!form) return;
    setError("");
    setSaving(true);
    setSaved(false);
    try {
      const updated = await apiFetch<UserDetail>(`/admin/users/${id}`, {
        method: "PATCH",
        body: JSON.stringify(formDataToPayload(form, "edit")),
      });
      setUser(updated);
      setForm(userToFormData(updated));
      setSaved(true);
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to save user");
    } finally {
      setSaving(false);
    }
  }

  async function deleteUser() {
    if (!confirm("Delete this user permanently?")) return;
    await apiFetch(`/admin/users/${id}`, { method: "DELETE" });
    router.push("/users");
  }

  if (!user || !form) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title={user.name || user.email}
        description={user.email}
        action={
          <div className="flex gap-2">
            <Button variant="danger" onClick={deleteUser}>
              Delete User
            </Button>
          </div>
        }
      />

      <div className="rounded-[20px] border border-border bg-surface p-6 shadow-sm">
        <div className="mb-6 flex flex-wrap items-center gap-2">
          {user.is_email_verified && <Badge variant="success">Verified</Badge>}
          {user.has_paid && (
            <Badge variant="success">
              {user.subscription_source || "Pro"}
            </Badge>
          )}
          {user.is_admin && <Badge variant="info">Admin</Badge>}
          {user.is_banned && <Badge variant="danger">Banned</Badge>}
        </div>

        {error && (
          <p className="mb-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-danger">
            {error}
          </p>
        )}
        {saved && (
          <p className="mb-4 rounded-2xl bg-green-50 px-4 py-3 text-sm text-green-700">
            User saved successfully
          </p>
        )}

        <UserForm data={form} onChange={setForm} mode="edit" />

        <div className="mt-6 flex justify-end gap-2 border-t border-border pt-6">
          <UserFormActions
            submitLabel="Save Changes"
            loading={saving}
            onCancel={() => router.push("/users")}
            onSubmit={saveUser}
          />
        </div>
      </div>

      {user.counts && (
        <div className="mt-6 rounded-[20px] border border-border bg-surface p-6 shadow-sm">
          <h2 className="mb-4 text-lg font-bold">Activity</h2>
          <div className="grid grid-cols-2 gap-3 md:grid-cols-3">
            {Object.entries(user.counts).map(([key, val]) => (
              <div
                key={key}
                className="rounded-2xl bg-surface-muted px-4 py-3 text-center"
              >
                <p className="text-xl font-bold">{val}</p>
                <p className="text-xs capitalize text-text-secondary">
                  {key.replace(/_/g, " ")}
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
