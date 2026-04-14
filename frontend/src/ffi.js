export function closeDialog(selector) {
  const el = document.querySelector(selector);
  if (el) el.close();
}

export function closeAllPopovers() {
  document.querySelectorAll("[popover]").forEach((el) => el.hidePopover());
}
