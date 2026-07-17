"use client";

import { useState } from "react";
import { apiFetch } from "@/lib/api";
import { ApiError } from "@/lib/api";
import { Button, PageHeader } from "@/components/ui";

type PushResult = {
  email: string;
  delivered: boolean;
  error: string | null;
};

export default function NotificationsPage() {
  const [channel, setChannel] = useState<"email" | "push">("push");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [target, setTarget] = useState<"all" | "custom">("custom");
  const [emails, setEmails] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [pushResults, setPushResults] = useState<PushResult[]>([]);

  async function handleSend(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage("");
    setError("");
    setPushResults([]);
    try {
      const emailList =
        target === "custom"
          ? emails.split(",").map((e) => e.trim()).filter(Boolean)
          : undefined;

      if (channel === "push") {
        const result = await apiFetch<{
          sent: number;
          total: number;
          results: PushResult[];
        }>("/admin/notifications/push", {
          method: "POST",
          body: JSON.stringify({
            title: subject,
            message: body,
            target_users: target,
            emails: emailList,
          }),
        });
        setPushResults(result.results);
        setMessage(
          `Push delivered to ${result.sent} of ${result.total} user(s).`
        );
      } else {
        const result = await apiFetch<{ message: string }>(
          "/admin/notifications/send",
          {
            method: "POST",
            body: JSON.stringify({
              subject,
              body,
              target_users: target === "all" ? "all" : "custom",
              emails: emailList,
            }),
          }
        );
        setMessage(result.message);
      }
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
        description="Send push notifications or bulk emails to users"
      />

      <form
        onSubmit={handleSend}
        className="max-w-2xl rounded-[20px] border border-border bg-surface p-6 shadow-sm"
      >
        <div className="mb-4">
          <label className="mb-1.5 block text-sm font-medium">Channel</label>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => setChannel("push")}
              className={`rounded-2xl px-5 py-2.5 text-sm font-medium border ${
                channel === "push"
                  ? "border-primary bg-primary/10 text-primary"
                  : "border-border bg-background"
              }`}
            >
              Push notification
            </button>
            <button
              type="button"
              onClick={() => setChannel("email")}
              className={`rounded-2xl px-5 py-2.5 text-sm font-medium border ${
                channel === "email"
                  ? "border-primary bg-primary/10 text-primary"
                  : "border-border bg-background"
              }`}
            >
              Email
            </button>
          </div>
          {channel === "push" && (
            <p className="mt-1.5 text-xs text-gray-500">
              Delivered instantly via OneSignal. The report below shows whether
              each user&apos;s device is linked &amp; subscribed — useful for
              testing.
            </p>
          )}
        </div>

        <div className="mb-4">
          <label className="mb-1.5 block text-sm font-medium">Recipients</label>
          <select
            value={target}
            onChange={(e) => setTarget(e.target.value as "all" | "custom")}
            className="w-full rounded-2xl border border-border bg-background px-4 py-2.5 text-sm"
          >
            <option value="custom">Specific user(s) by email</option>
            <option value="all">All verified users</option>
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
          <label className="mb-1.5 block text-sm font-medium">
            {channel === "push" ? "Title" : "Subject"}
          </label>
          <input
            type="text"
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            required
            className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary"
            placeholder={channel === "push" ? "Protein check 🥩" : ""}
          />
        </div>

        <div className="mb-6">
          <label className="mb-1.5 block text-sm font-medium">Message</label>
          <textarea
            value={body}
            onChange={(e) => setBody(e.target.value)}
            required
            rows={channel === "push" ? 4 : 8}
            className="w-full rounded-2xl border border-border bg-background px-4 py-3 text-sm outline-none focus:border-primary"
            placeholder={
              channel === "push"
                ? "Mohamed, you still have 40 g of protein to go today!"
                : ""
            }
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

        {pushResults.length > 0 && (
          <div className="mb-4 overflow-hidden rounded-2xl border border-border">
            <table className="w-full text-sm">
              <thead className="bg-background text-left">
                <tr>
                  <th className="px-4 py-2.5 font-medium">User</th>
                  <th className="px-4 py-2.5 font-medium">Status</th>
                </tr>
              </thead>
              <tbody>
                {pushResults.map((r) => (
                  <tr key={r.email} className="border-t border-border">
                    <td className="px-4 py-2.5">{r.email}</td>
                    <td className="px-4 py-2.5">
                      {r.delivered ? (
                        <span className="text-green-700">✓ Delivered</span>
                      ) : (
                        <span className="text-danger">
                          ✗ {r.error || "Failed"}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <Button type="submit" disabled={loading}>
          {loading
            ? "Sending..."
            : channel === "push"
            ? "Send Push"
            : "Send Email"}
        </Button>
      </form>
    </div>
  );
}
