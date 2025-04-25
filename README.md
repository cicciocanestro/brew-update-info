# Brew Update Info

Script Bash per visualizzare informazioni dettagliate sui pacchetti Homebrew che richiedono aggiornamenti e sui nuovi pacchetti disponibili nel repository.

## Caratteristiche

- Esegue `brew update` per aggiornare il repository Homebrew
- Mostra informazioni dettagliate (`brew info`) su ogni pacchetto da aggiornare
- Identifica e mostra informazioni sui nuovi pacchetti (formule e cask) disponibili
- Offre la possibilità di eseguire `brew upgrade` alla fine

## Installazione

```bash
# Clona il repository
git clone https://github.com/tuousername/brew-update-info.git

# Entra nella directory
cd brew-update-info

# Rendi lo script eseguibile
chmod +x brew-update-info.sh
