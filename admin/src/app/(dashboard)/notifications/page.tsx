"use client";

import { useState } from "react";
import { apiFetch } from "@/lib/api";
import { ApiError } from "@/lib/api";
import { Button, PageHeader } from "@/components/ui";

export default function NotificationsPage() {
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [target, setTarget] = useState<"all" | "custom">("all");
  const [emails, setEmails] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");

  async function handleSend(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage("");
    setError("");
    try {
      const result = await apiFetch<{ message: string }>(
        "/admin/notifications/send",
        {
          method: "POST",
          body: JSON.stringify({
            subject,
            body,
            target_users: target === "all" ? "all" : "custom",
            emails:
              target === "custom"
                ? emails.split(",").map((e) => e.trim()).filter(Boolean)
                : undefined,
          }),
        }
      );
      setMessage(result.message);
      setSubject("");
      setBody("");
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Failed to send");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <PageHeader
        title="Notifications"
        description="Send bulk email notifications to users"
      />

      <form
        onSubmit={handleSend}
        className="max-w-2xl rounded-[20px] border border-border bg-surface p-6 shadow-sm"
      >
        <div className="mb-4">
          <label className="mb-1.5 block text-sm font-medium">Recipients</label>
          <select
            value={target}
            onChange={(e) => setTarget(e.target.value as "all" | "custom")}
            className="w-full rounded-2xl border border-border bg-background px-4 py-2.5 text-sm"
          >
            <option value="all">All verified users</option>
            <option value="custom">Custom email list</option>
          </select>
        </div>

        {target === "custom" && (
          <div className="mb-4">
            <label className="mb-1.5 block text-sm font-medium">
              Emails (comma-separated)
            </label>
            <textarea
              value={emails}
              onChange={(e) => setEmails(e.target.value)}
              rows={3}
              className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary"
              placeholder="user1@example.com, user2@example.com"
            />
          </div>
        )}

        <div className="mb-4">
          <label className="mb-1.5 block text-sm font-medium">Subject</label>
          <input
            type="text"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            required
            className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary"
          />
        </div>

        <div className="mb-6">
          <label className="mb-1.5 block text-sm font-medium">Message</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            required
            rows={8}
            className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary"
          />
        </div>

        {message && (
          <p className="mb-4 rounded-2xl bg-green-50 px-4 py-3 text-sm text-green-700">
            {message}
          </p>
        )}
        {error && (
          <p className="mb-4 rounded-2xl bg-red-50 px-4 py-3 text-sm text-danger">
            {error}
          </p>
        )}

        <Button type="submit" disabled={loading}>
          {loading ? "Sending..." : "Send Notification"}
        </Button>
      </form>
    </div>
  );
}
