import { ApplicationController } from './application_controller';
import { FlashMessage } from '../components/shared/FlashMessage';
import { createRoot } from 'react-dom/client';


interface SpeechRecognition extends EventTarget {
  continuous: boolean;
  interimResults: boolean;
  lang: string;
  onstart: (() => void) | null;
  onresult: ((event: SpeechRecognitionEvent) => void) | null;
  onend: (() => void) | null;
  onerror: ((event: Event) => void) | null;
  start(): void;
  stop(): void;
}

interface SpeechRecognitionEvent extends Event {
  resultIndex: number;
  results: SpeechRecognitionResultList;
}

export class SpeechToTextController extends ApplicationController {
  static targets = ['input', 'instructeurActions'];
  declare readonly inputTarget: HTMLInputElement;
  declare readonly instructeurActionsTarget: HTMLInputElement;
  declare readonly hasInstructeurActionsTarget: boolean;
  
  declare speechRecognition: SpeechRecognition;
  declare speechRecognitionSupported: boolean;

  declare interimTranscript: string;
  declare finalTranscript: string;
  declare selectionStart: number;

  connect() {
    const SpeechRecognition =
      (window as any)['SpeechRecognition'] || (window as any)['webkitSpeechRecognition'];

    this.speechRecognitionSupported = SpeechRecognition ? true : false;
    if (this.speechRecognitionSupported) {
      this.speechRecognition = new SpeechRecognition();
      this.setupSpeechRecognitionEvents();
      this.setupSpeechRecognitionProperties();
    } else {
      const button = this.inputTarget.parentElement?.querySelector('#button-speech-to-text');
      button?.classList.add('speech_recognition_not_supported');
    }
  }

  setupSpeechRecognitionProperties() {
    this.speechRecognition.continuous = this.hasInstructeurActionsTarget ? false : true;
    this.speechRecognition.interimResults = this.hasInstructeurActionsTarget ? false : true;
    this.speechRecognition.lang = 'fr-FR';
  }

  setupSpeechRecognitionEvents() {
    this.speechRecognition.onstart = () => {
      this.replaceByIcon('stop');
    };

    this.speechRecognition.onresult = (event: SpeechRecognitionEvent) => {
      if (this.hasInstructeurActionsTarget) {
        this.extractTranscriptsInstructeur(event)
      } else {
        this.extractTranscriptsInput(event);
      }
    };

    this.speechRecognition.onend = () => {
      this.replaceByIcon('microphone');
    };

    this.speechRecognition.onerror = () => {
      // TODO: Manage error.
    };
  }

  onClick() {
    if(!this.speechRecognition) {
      this.error("La reconnaissance vocale n'est pas supportée par votre navigateur.", 'alert')
    }
    else if (this.hasInstructeurActionsTarget) {
      this.manageInstructeurActions();
    } else {
      this.manageUserInput();
    }
  }

  extractTranscriptsInstructeur(event: SpeechRecognitionEvent) {
    const dossierAccepted = ["ok", "accepté", "accepter", "j'accepte"];

    // The last character is sometimes a punctuation mark.
    const result = event.results[0][0].transcript.replace(/[^a-zA-Z]+$/, '').toLowerCase();
    
    if (dossierAccepted.includes(result)) {
      const form = document.getElementById('speech_to_text_instructeur_actions') as HTMLFormElement;
      const inputProcessAction = form?.querySelector('[name="process_action"]') as HTMLInputElement;
      inputProcessAction.value = 'accepter';
      form?.dispatchEvent(new Event('submit', { bubbles: true }));
    }
    else {
      this.error("L'action n'est pas comprise ou n'est pas supportée.", 'alert');
    }
  }

  extractTranscriptsInput(event: SpeechRecognitionEvent) {
    let transcript = '';
    let isFinal = false;

    for (let i = event.resultIndex; i < event.results.length; i++) {
      const result = event.results[i]; 

      if (result.isFinal) { 
        this.finalTranscript = result[0].transcript;        
        isFinal = true;
      } else {
        transcript += result[0].transcript;
      }
    }

    if (!isFinal) {
      this.interimTranscript = transcript;
    }

    this.updateInputValue(isFinal);

    if (isFinal) { 
      this.interimTranscript = '';
      this.selectionStart += this.finalTranscript.length;  
    }
  }

  updateInputValue(isFinal: boolean) {
    const input = this.inputTarget;
    const selectionEnd = input.selectionEnd ?? 0;
    const currentValue = input.value;

    const beforeSelection = currentValue.substring(0, this.selectionStart);
    const afterSelection = currentValue.substring(selectionEnd);

    let updatedTranscript = isFinal ? this.finalTranscript : this.interimTranscript;

    if (!isFinal) {      
      updatedTranscript = this.formatTranscript(beforeSelection, updatedTranscript, afterSelection);

      input.value = beforeSelection + updatedTranscript + afterSelection;
      input.selectionEnd = this.selectionStart + updatedTranscript.length;

      this.interimTranscript = updatedTranscript;
    } 
    else {
      updatedTranscript = this.formatTranscript(beforeSelection, updatedTranscript, afterSelection);

      input.value = input.value.replace(this.interimTranscript, updatedTranscript);
      input.dispatchEvent(new Event('input', { bubbles: true }));

      input.selectionEnd = this.selectionStart + updatedTranscript.length;
    }
  }

  formatTranscript(beforeSelection: string, updatedTranscript: string, afterSelection: string) {
    updatedTranscript = updatedTranscript.charAt(0).toLowerCase() + updatedTranscript.slice(1);

    // Start the sentence with a capital letter.
    if (this.selectionStart == 0) {
      return updatedTranscript.charAt(0).toUpperCase() + updatedTranscript.slice(1);
    } 
    // New sentence.
    else if (beforeSelection.trimStart().endsWith('.')) {
      return ' ' + updatedTranscript.trimStart().charAt(0).toUpperCase() + updatedTranscript.trimStart().slice(1);
    }
    // Remove '.' if it is an addition at the end of a line.
    else if(!afterSelection.trimStart().startsWith('.')){
      if(afterSelection.startsWith(' ')) {
        return updatedTranscript.slice(0, -1);
      } else {
        return updatedTranscript.slice(0, -1)  + " ";
      }
    }

    return updatedTranscript;
  }

  manageInstructeurActions() {
    const button = this.instructeurActionsTarget.parentElement?.querySelector('#button-speech-to-text');
    const stopIcon = button?.querySelector('.stop-speech-to-text');
    const microphoneIcon = button?.querySelector('.microphone-speech-to-text');

    if(stopIcon?.classList.contains('stop-recording-hidden')) {
      stopIcon?.classList.replace('stop-recording-hidden', 'stop-recording-visible');
      microphoneIcon?.classList.add('microphoneHidden');
      button?.classList.add('fr-tag-bug');
      this.startRecording();
    } else {
      stopIcon?.classList.replace('stop-recording-visible', 'stop-recording-hidden');
      microphoneIcon?.classList.remove('microphoneHidden');
      button?.classList.remove('fr-tag-bug');
      this.stopRecording();
    }
  }

  manageUserInput() {
    const stopIcon = this.inputTarget.parentElement?.querySelector('.stop-speech-to-text');
    this.insertAccordingCursor();

    if (stopIcon?.classList.contains('stop-recording-hidden')) {
      this.startRecording();
    } else {
      this.stopRecording();
    }
  }

  replaceByIcon(type: string) {
    const button = this.inputTarget.parentElement?.querySelector('#button-speech-to-text');
    const stopIcon = button?.querySelector('.stop-speech-to-text');
    const microphoneIcon = button?.querySelector('.microphone-speech-to-text');

    if(type === 'stop') {
      stopIcon?.classList.replace('stop-recording-hidden', 'stop-recording-visible');
      microphoneIcon?.classList.add('microphoneHidden');
      button?.classList.add('fr-tag-bug');
    } else if(type === 'microphone') {
      stopIcon?.classList.replace('stop-recording-visible', 'stop-recording-hidden');
      microphoneIcon?.classList.remove('microphoneHidden');
      button?.classList.remove('fr-tag-bug');
    }
  }

  insertAccordingCursor() {
    const input = this.inputTarget;

    input.addEventListener('click', () => {      
      this.selectionStart = input.selectionStart ?? 0;
    });
    this.selectionStart = input.selectionStart ?? 0;
  }

  startRecording() {
    this.interimTranscript = '';
    this.finalTranscript = '';
    this.speechRecognition.start();
  }

  stopRecording() {
    this.speechRecognition.stop();
  }

  error(message: string, level: string){
    if (this.hasInstructeurActionsTarget) {
      const flashMessageContainer = document.getElementById('flash_messages');
      if (!flashMessageContainer) {
        console.error('Flash message container not found!');
        return;
      }

      const root = createRoot(flashMessageContainer);
      root.render(
        <FlashMessage
          message={message}
          level={level}
        />
      );
    } else {
      const error = this.inputTarget.parentElement?.parentElement?.querySelector('#speech_recognition_not_supported');
      error?.classList.remove('hidden');
    }
  }
}