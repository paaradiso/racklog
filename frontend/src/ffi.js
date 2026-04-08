export function closeDialog(selector) {
  const el = document.querySelector(selector);
  if (el) el.close();
}
