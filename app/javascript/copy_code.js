document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('code.cursor-pointer').forEach(el => {
    el.addEventListener('click', () => {
      const text = el.textContent;
      navigator.clipboard.writeText(text).then(() => {
        const originalColor = el.style.color;
        el.style.color = '#22c55e';
        setTimeout(() => {
          el.style.color = originalColor;
        }, 800);
      }).catch(() => {
        alert('コピーに失敗しました。');
      });
    });
  });
});
