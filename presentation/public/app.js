const titleEl = document.querySelector("#slide-title");
const subtitleEl = document.querySelector("#slide-subtitle");
const contentEl = document.querySelector("#slide-content");
const progressEl = document.querySelector("#progress");
const notesEl = document.querySelector("#slide-notes");
const prevBtn = document.querySelector("#prev-btn");
const nextBtn = document.querySelector("#next-btn");
const fullscreenBtn = document.querySelector("#fullscreen-btn");

let slides = [];
let index = 0;

async function loadSlides() {
  try {
    const res = await fetch("/api/slides");
    if (!res.ok) throw new Error("Failed to load slides");
    slides = await res.json();
    index = 0;
    render();
  } catch (err) {
    contentEl.innerHTML = `<p class="error">Unable to load slides: ${err.message}</p>`;
  }
}

function render() {
  if (!slides.length) {
    contentEl.innerHTML = "<p>Loading slides…</p>";
    titleEl.textContent = "";
    subtitleEl.textContent = "";
    progressEl.textContent = "";
    notesEl.textContent = "";
    return;
  }

  const slide = slides[index];
  titleEl.textContent = slide.title ?? "";
  subtitleEl.textContent = slide.subtitle ?? "";
  progressEl.textContent = `${index + 1} / ${slides.length}`;
  notesEl.textContent = slide.notes ?? "";
  prevBtn.disabled = index === 0;
  nextBtn.disabled = index >= slides.length - 1;

  contentEl.innerHTML = "";
  if (slide.type === "iframe") {
    const iframe = document.createElement("iframe");
    iframe.src = slide.url;
    iframe.allowFullscreen = true;
    iframe.title = slide.title ?? "Embedded frame";
    contentEl.appendChild(iframe);
  } else {
    const list = document.createElement("ul");
    (slide.body ?? []).forEach((item) => {
      const li = document.createElement("li");
      li.textContent = item;
      list.appendChild(li);
    });
    if (!list.children.length) {
      list.innerHTML = "<li>Add bullet points in slides.json</li>";
    }
    contentEl.appendChild(list);
  }
}

function changeSlide(delta) {
  if (!slides.length) return;
  index = Math.min(Math.max(index + delta, 0), slides.length - 1);
  render();
}

function toggleFullscreen() {
  const elem = document.documentElement;
  if (!document.fullscreenElement) {
    elem.requestFullscreen?.();
  } else {
    document.exitFullscreen?.();
  }
}

prevBtn.addEventListener("click", () => changeSlide(-1));
nextBtn.addEventListener("click", () => changeSlide(1));
fullscreenBtn.addEventListener("click", toggleFullscreen);

document.addEventListener("keydown", (event) => {
  if (event.key === "ArrowRight" || event.key === " ") {
    changeSlide(1);
  } else if (event.key === "ArrowLeft") {
    changeSlide(-1);
  }
});

loadSlides();
