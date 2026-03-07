const sections = document.querySelectorAll("section[id]");
const menuLinks = document.querySelectorAll(".menu a");

window.addEventListener("scroll", () => {
    let scrollY = window.pageYOffset;

    sections.forEach(section => {
        const sectionHeight = section.offsetHeight;
        const sectionTop = section.offsetTop - 100; // ajuste de margem
        const sectionId = section.getAttribute("id");

        if(scrollY > sectionTop && scrollY <= sectionTop + sectionHeight){
            menuLinks.forEach(link => link.classList.remove("ativo"));
            const activeLink = document.querySelector(`.menu a[href="#${sectionId}"]`);
            if(activeLink){activeLink.classList.add("ativo");}
        }
    });
});
