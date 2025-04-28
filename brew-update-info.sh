#!/bin/bash

# Colori per una migliore leggibilità
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# File temporanei
BREW_UPDATE_OUTPUT_FILE="/tmp/brew_update_output.txt"
NEW_FORMULAE_FILE="/tmp/brew_new_formulae.txt"
NEW_CASKS_FILE="/tmp/brew_new_casks.txt"

# Funzione per mostrare l'URL del pacchetto
show_package_url() {
    local package_name=$1
    local package_type=$2
    
    echo -e "\n${YELLOW}===========================================================${NC}"
    echo -e "${GREEN}$package_type: ${BLUE}$package_name${NC}"
    
    # Controlla che il pacchetto esista prima di eseguire brew info
    if brew info --json=v1 "$package_name" &>/dev/null; then
        # Estrai solo l'URL dal brew info
        url=$(brew info "$package_name" | grep -E "https?://" | head -1 | awk '{print $1}')
        
        if [ -n "$url" ]; then
            echo -e "${GREEN}URL: ${BLUE}$url${NC}"
        else
            echo -e "${RED}Nessun URL trovato per questo pacchetto${NC}"
        fi
    else
        echo -e "${RED}Pacchetto non trovato nel repository${NC}"
    fi
    
    echo -e "${YELLOW}===========================================================${NC}"
    echo ""
}

# Funzione per estrarre i nuovi pacchetti dall'output di brew update
extract_new_packages() {
    # Estrai i nomi delle nuove formule
    grep -A 100 "New Formulae" "$BREW_UPDATE_OUTPUT_FILE" | 
    grep -B 100 "New Casks\|Updated Formulae\|Deleted Formulae\|Outdated Formulae\|Updating Homebrew" |
    grep -v "New Formulae\|New Casks\|Updated Formulae\|Deleted Formulae\|Outdated Formulae\|Updating Homebrew\|=\|^$" > "$NEW_FORMULAE_FILE"
    
    # Estrai i nomi dei nuovi cask
    grep -A 100 "New Casks" "$BREW_UPDATE_OUTPUT_FILE" | 
    grep -B 100 "Updated Formulae\|Deleted Formulae\|Outdated Formulae\|Updating Homebrew" |
    grep -v "New Formulae\|New Casks\|Updated Formulae\|Deleted Formulae\|Outdated Formulae\|Updating Homebrew\|=\|^$" > "$NEW_CASKS_FILE"
}

# Esegui brew update e cattura l'output
echo -e "${BLUE}Esecuzione di brew update...${NC}"
brew update 2>&1 | tee "$BREW_UPDATE_OUTPUT_FILE"

# Ottieni l'elenco dei pacchetti da aggiornare
echo -e "${BLUE}Controllo pacchetti da aggiornare...${NC}"
outdated_packages=$(brew outdated --verbose)

# Estrai i nuovi pacchetti dall'output di brew update
echo -e "${BLUE}Controllo pacchetti nuovi nel repository...${NC}"
extract_new_packages

# Leggi i nuovi pacchetti dai file temporanei
new_formulae=$(cat "$NEW_FORMULAE_FILE" | tr -d ' ')
new_casks=$(cat "$NEW_CASKS_FILE" | tr -d ' ')

# Verifica se ci sono pacchetti da aggiornare o nuovi
if [ -z "$outdated_packages" ] && [ -z "$new_formulae" ] && [ -z "$new_casks" ]; then
    echo -e "${GREEN}Nessun pacchetto da aggiornare e nessun pacchetto nuovo nel repository. Tutto è aggiornato.${NC}"
    rm -f "$BREW_UPDATE_OUTPUT_FILE" "$NEW_FORMULAE_FILE" "$NEW_CASKS_FILE"
    exit 0
fi

# Mostra informazioni sui pacchetti da aggiornare
if [ -n "$outdated_packages" ]; then
    # Conta i pacchetti da aggiornare
    package_count=$(echo "$outdated_packages" | wc -l | tr -d ' ')
    echo -e "${YELLOW}Trovati $package_count pacchetti da aggiornare:${NC}"

    # Per ogni pacchetto da aggiornare, mostra l'URL
    while IFS= read -r line; do
        # Estrai il nome del pacchetto (prima colonna)
        package_name=$(echo "$line" | awk '{print $1}')
        echo -e "${YELLOW}Versioni: $line${NC}"
        show_package_url "$package_name" "Pacchetto da aggiornare"
    done <<< "$outdated_packages"
fi

# Mostra URL delle nuove formule
if [ -n "$new_formulae" ]; then
    # Conta le nuove formule
    formula_count=$(cat "$NEW_FORMULAE_FILE" | wc -l | tr -d ' ')
    
    if [ "$formula_count" -gt 0 ]; then
        echo -e "${YELLOW}Trovate $formula_count nuove formule nel repository Homebrew:${NC}"
        
        while IFS= read -r formula; do
            if [ -n "$formula" ]; then
                show_package_url "$formula" "Nuova formula"
            fi
        done < "$NEW_FORMULAE_FILE"
    fi
fi

# Mostra URL dei nuovi cask
if [ -n "$new_casks" ]; then
    # Conta i nuovi cask
    cask_count=$(cat "$NEW_CASKS_FILE" | wc -l | tr -d ' ')
    
    if [ "$cask_count" -gt 0 ]; then
        echo -e "${YELLOW}Trovati $cask_count nuovi cask nel repository Homebrew:${NC}"
        
        while IFS= read -r cask; do
            if [ -n "$cask" ]; then
                show_package_url "$cask" "Nuovo cask"
            fi
        done < "$NEW_CASKS_FILE"
    fi
fi

# Chiedi all'utente se vuole procedere con l'aggiornamento
read -p "Vuoi eseguire 'brew upgrade' per aggiornare tutti i pacchetti? (s/n): " choice

if [[ "$choice" =~ ^[Ss]$ ]]; then
    echo -e "${BLUE}Esecuzione di brew upgrade...${NC}"
    brew upgrade
    echo -e "${GREEN}Aggiornamento completato!${NC}"
else
    echo -e "${RED}Aggiornamento annullato.${NC}"
fi

# Pulizia file temporanei
rm -f "$BREW_UPDATE_OUTPUT_FILE" "$NEW_FORMULAE_FILE" "$NEW_CASKS_FILE"
