import { Directive, ElementRef, HostListener, OnDestroy, OnInit } from '@angular/core';

/**
 * Convierte un contenedor con overflow horizontal en uno que se puede
 * desplazar con la rueda del ratón (vertical -> horizontal) y arrastrando
 * con el mouse, mejorando la experiencia en gráficos anchos.
 */
@Directive({
  selector: '[appHorizontalScroll]',
  standalone: true,
})
export class HorizontalScrollDirective implements OnInit, OnDestroy {
  private readonly el: HTMLElement;
  private isDown = false;
  private startX = 0;
  private scrollLeft = 0;
  private wheelHandler!: (e: WheelEvent) => void;

  constructor(el: ElementRef<HTMLElement>) {
    this.el = el.nativeElement;
  }

  ngOnInit(): void {
    this.el.style.cursor = 'grab';
    this.el.style.scrollBehavior = 'smooth';
    // passive: false para poder hacer preventDefault en la rueda.
    this.wheelHandler = (e: WheelEvent) => {
      if (Math.abs(e.deltaY) > Math.abs(e.deltaX)) {
        e.preventDefault();
        this.el.scrollLeft += e.deltaY;
      }
    };
    this.el.addEventListener('wheel', this.wheelHandler, { passive: false });
  }

  ngOnDestroy(): void {
    this.el.removeEventListener('wheel', this.wheelHandler);
  }

  @HostListener('mousedown', ['$event'])
  onMouseDown(e: MouseEvent): void {
    this.isDown = true;
    this.el.style.cursor = 'grabbing';
    this.startX = e.pageX - this.el.offsetLeft;
    this.scrollLeft = this.el.scrollLeft;
  }

  @HostListener('mouseleave')
  onMouseLeave(): void {
    this.isDown = false;
    this.el.style.cursor = 'grab';
  }

  @HostListener('mouseup')
  onMouseUp(): void {
    this.isDown = false;
    this.el.style.cursor = 'grab';
  }

  @HostListener('mousemove', ['$event'])
  onMouseMove(e: MouseEvent): void {
    if (!this.isDown) return;
    e.preventDefault();
    const x = e.pageX - this.el.offsetLeft;
    const walk = (x - this.startX) * 1.25;
    this.el.scrollLeft = this.scrollLeft - walk;
  }
}
