#!/bin/bash

# Colori per una migliore leggibilità
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# File temporaneo per memorizzare l'output di brew tap-info prima dell'aggiornamento
PREV_TAP_INFO_FILE="/tmp/brew_tap_info_previous.txt"
BREW_UPDATE_OUTPUT_FILE="/tmp/brew_update_output.txt"

# Funzione per mostrare l'URL del pacchetto
show_package_url() {
    local package_name=$1
    local package_type=$2
    
    echo -e "\n${YELLOW}===========================================================${NC}"
    echo -e "${GREEN}$package_type: ${BLUE}$package_name${NC}"
    
    # Estrai solo l'URL dal brew info
    url=$(brew info "$package_name" | grep -E "https?://" | head -1 | awk '{print $1}')
    
    if [ -n "$url" ]; then
        echo -e "${GREEN}URL: ${BLUE}$url${NC}"
    else
        echo -e "${RED}Nessun URL trovato per questo pacchetto${NC}"
    fi
    
    echo -e "${YELLOW}===========================================================${NC}"
    echo ""
}

# Funzione per estrarre i nuovi pacchetti dall'output di brew update
extract_new_packages() {
    # Cerca righe che contengono "==> New Formulae", "==> New Casks" o simili nell'output
    grep -A 100 "==> New" "$BREW_UPDATE_OUTPUT_FILE" | grep -v "==> " | grep -v "^$" | sort | uniq
}

# Esegui brew update e cattura l'output
echo -e "${BLUE}Esecuzione di brew update...${NC}"
brew update 2>&1 | tee "$BREW_UPDATE_OUTPUT_FILE"

# Ottieni l'elenco dei pacchetti da aggiornare
echo -e "${BLUE}Controllo pacchetti da aggiornare...${NC}"
outdated_packages=$(brew outdated --verbose)

# Estrai i nuovi pacchetti dall'output di brew update
echo -e "${BLUE}Controllo pacchetti nuovi nel repository...${NC}"
new_packages=$(extract_new_packages)

# Verifica se ci sono pacchetti da aggiornare o nuovi
if [ -z "$outdated_packages" ] && [ -z "$new_packages" ]; then
    echo -e "${GREEN}Nessun pacchetto da aggiornare e nessun pacchetto nuovo nel repository. Tutto è aggiornato.${NC}"
    rm -f "$BREW_UPDATE_OUTPUT_FILE"
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

# Mostra URL dei pacchetti nuovi
if [ -n "$new_packages" ]; then
    # Conta i nuovi pacchetti
    package_count=$(echo "$new_packages" | wc -l | tr -d ' ')
    echo -e "${YELLOW}Trovati $package_count nuovi pacchetti nel repository Homebrew:${NC}"

    while IFS= read -r package; do
        if [ -n "$package" ]; then
            show_package_url "$package" "Nuovo pacchetto"
        fi
    done <<< "$new_packages"
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
rm -f "$BREW_UPDATE_OUTPUT_FILE"
