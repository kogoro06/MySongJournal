export function togglePasswordVisibility(inputId, button) {
  const input = document.getElementById(inputId);
  if (input.type === "password") {
    input.type = "text";
    button.textContent = "🙈"; // Hide icon
  } else {
    input.type = "password";
    button.textContent = "👁"; // Show icon
  }
} 