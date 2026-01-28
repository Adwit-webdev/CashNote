# 💵CashNote📝

**Where your shopping list meets your wallet — and they finally cooperate.**

CashNote is a smart productivity + finance app I built as my GDG Club Induction Project.

The idea is simple:  
Why write a shopping list in one app, then track expenses in another?

CashNote combines both.

Check off an item, confirm you bought it, and the cost is instantly added to your daily expenses.  
Clean. Seamless. Budget-friendly.

---

## 🚀 The Coolest Feature: Scan → Add → Done

### 📷 Barcode Scanner Shopping Magic  
This is CashNote’s standout feature:

* Scan any product barcode directly inside a note  
* The app fetches the product name & price  
* Instantly adds it to your checklist  
* And when you tick it off… it syncs into your Expense Tracker automatically  

Shopping + spending tracked in one flow — no manual typing, no switching apps.

---

## ✨ Key Features

### 🗒️ Smart Notes & Checklists
* **Pinterest-style layout:** Notes arranged in a clean masonry grid.
* **Auto-icons:** Type “milk” → CashNote adds 🥛 automatically.
* **Quantity control:** Tap `x1` to increase, long-press to reset, or type manually.
* **Smart tick sync:** Checked priced items instantly become transactions.

---

### 💳 Expense Tracking
* **Dashboard view:** Income, expenses, and total balance on the home screen.
* **Category pie chart:** Dark-themed visual breakdown of spending.
* **Transaction history:** Long-press to delete mistakes easily.

---

### 📈 Budget & Analytics
* **Monthly budgeting:** Set a limit (₹5000) with a progress bar that turns red if you overspend.
* **Price memory:** Scan once, and CashNote remembers product prices for next time.
* **Weekly & monthly breakdowns:** Compare spending patterns over time.

---

## 🎮 Button Guide (Quick Navigation)

### Home Screen
* **➕ FAB:** Add quick Income or Expense (Salary, Bus ticket, etc.)
* **📅 Calendar Icon:** Opens Budget & Analytics dashboard
* **⚙️ Settings Icon:** Theme toggles and app settings

---

### Notes Screen
* **Search Bar:** Filter notes instantly
* **➕ FAB:** Create a new note or checklist

---

### Inside a Note (Editor)
* **📷 Barcode Scanner:** Scan product → fetch details → add to list
* **⏰ Reminder Bell:** Schedule shopping reminders
* **📤 Share Icon:** Share formatted list to WhatsApp or other apps
* **🎨 Palette Icon:** Change note background color
* **✅ Checkbox:** Mark items done + sync expense automatically

---

## 🛠️ Tech Stack (Under the Hood)

* **Framework:** Flutter (Dart)
* **Backend:** Firebase Firestore (real-time sync)
* **State Management:** `setState` (simple + performant)
* **Packages Used:**
  * `flutter_local_notifications` → reminders  
  * `mobile_scanner` → barcode scanning  
  * `fl_chart` → analytics charts  

---
## 📱 Installation

1.  Clone the repository.
2.  Run `flutter pub get` to install dependencies.
3.  Set up your own `google-services.json` in `android/app/` if you want to use your own Firebase instance.
4.  Run `flutter run`.

**Built with curiosity (and caffeine)**
