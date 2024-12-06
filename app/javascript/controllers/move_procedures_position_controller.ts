import { ApplicationController } from './application_controller';

export class MoveProceduresPositionController extends ApplicationController {
  connect() {
    this.updateButtonsStates();
  }

  async moveUp(event: Event) {
    event.preventDefault();
    const button = event.currentTarget as HTMLButtonElement;
    const upCard = button.closest('.fr-card');

    await this.switchCards(upCard!, upCard!.previousElementSibling!);

    upCard!.parentNode!.insertBefore(upCard!, upCard!.previousElementSibling);
    this.updateButtonsStates();
  }

  async moveDown(event: Event) {
    event.preventDefault();
    const button = event.currentTarget as HTMLButtonElement;
    const downCard = button.closest('.fr-card');

    await this.switchCards(downCard!.nextElementSibling!, downCard!);

    downCard!.parentNode!.insertBefore(downCard!.nextElementSibling!, downCard);
    this.updateButtonsStates();
  }

  private async switchCards(upCard: Element, downCard: Element): Promise<void> {
    const upCardRect = upCard.getBoundingClientRect();
    const downCardRect = downCard.getBoundingClientRect();

    const upAnimation = upCard.animate(
      [
        { transform: `translateY(0)` },
        { transform: `translateY(${downCardRect.top - upCardRect.top}px)` }
      ],
      { duration: 300, easing: 'ease-in-out' }
    );

    const downAnimation = downCard.animate(
      [
        { transform: `translateY(0)` },
        { transform: `translateY(${upCardRect.top - downCardRect.top}px)` }
      ],
      { duration: 300, easing: 'ease-in-out' }
    );

    await Promise.all([upAnimation.finished, downAnimation.finished]);
  }

  private updateButtonsStates() {
    const buttons = [
      ...this.element.querySelectorAll('button')
    ] as HTMLButtonElement[];
    buttons.forEach(
      (button, index) =>
        (button.disabled = index == 0 || index == buttons.length - 1)
    );
  }
}
