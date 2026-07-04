// Cấu hình tài khoản giả lập với vai trò
const USERS = [
  { username: "admin", password: "123", role: "admin" },
  { username: "nhanvien", password: "123", role: "staff" }
];

const loginForm = document.getElementById("loginForm");
const loginBtn = document.getElementById("loginBtn");
const errorMsg = document.getElementById("errorMsg");
const successMsg = document.getElementById("successMsg");
const usernameInput = document.getElementById("username");
const passwordInput = document.getElementById("password");
const forgotLink = document.getElementById("forgotLink");

document.addEventListener("DOMContentLoaded", () => {
  usernameInput.focus();
  loginForm.addEventListener("submit", handleLogin);
  forgotLink.addEventListener("click", handleForgotPassword);

  // Nếu đã đăng nhập, chuyển thẳng luôn
  if (sessionStorage.getItem("isLoggedIn") === "true") {
    window.location.href = "Giaodienver2.html";
  }
});

function handleLogin(e) {
  e.preventDefault();
  const username = usernameInput.value.trim();
  const password = passwordInput.value;

  hideMessages();

  if (!username || !password) {
    showError("Vui lòng nhập đầy đủ thông tin!");
    return;
  }

  loginBtn.disabled = true;
  loginBtn.textContent = "Đang xử lý...";

  setTimeout(() => {
    const foundUser = USERS.find(user => user.username === username && user.password === password);

    if (foundUser) {
      showSuccess("Đăng nhập thành công!");
      sessionStorage.setItem("isLoggedIn", "true");
      sessionStorage.setItem("username", foundUser.username);
      sessionStorage.setItem("userRole", foundUser.role); // Lưu vai trò người dùng

      setTimeout(() => {
        window.location.href = "Giaodienver2.html";
      }, 1500);
    } else {
      showError("Sai tên đăng nhập hoặc mật khẩu!");
      loginBtn.disabled = false;
      loginBtn.textContent = "Đăng nhập";
      passwordInput.value = "";
    }
  }, 1000);
}

function showError(message) {
  errorMsg.textContent = message;
  errorMsg.style.display = "block";
}

function showSuccess(message) {
  successMsg.textContent = message;
  successMsg.style.display = "block";
}

function hideMessages() {
  errorMsg.style.display = "none";
  successMsg.style.display = "none";
}

function handleForgotPassword(e) {
  e.preventDefault();
  const email = prompt("Vui lòng nhập email để khôi phục mật khẩu:");
  if (email) {
    if (isValidEmail(email)) {
      alert("Hướng dẫn đặt lại mật khẩu đã được gửi đến email của bạn.");
    } else {
      alert("Email không hợp lệ.");
    }
  }
}

function isValidEmail(email) {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(String(email).toLowerCase());
}