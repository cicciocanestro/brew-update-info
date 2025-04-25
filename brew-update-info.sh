#!/bin/bash

# Colori per una migliore leggibilità
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

# File temporaneo per memorizzare lo stato precedente
PREV_FORMULAS_FILE="/tmp/brew_formulas_previous.txt"
PREV_CASKS_FILE="/tmp/brew_casks_previous.txt"

# Funzione per mostrare informazioni sul pacchetto
show_package_info() {
    local package_name=$1
    local package_type=$2
    
    echo -e "\n${YELLOW}===========================================================${NC}"
    echo -e "${GREEN}Informazioni per ${package_type}: ${BLUE}$package_name${NC}"
    echo -e "${YELLOW}===========================================================${NC}"
    
    # Mostra informazioni dettagliate sul pacchetto
    brew info "$package_name"
    
    echo -e "\n${YELLOW}===========================================================${NC}"
    echo ""
}

# Salva lo stato attuale prima dell'aggiornamento
echo -e "${BLUE}Salvataggio stato attuale dei pacchetti Homebrew...${NC}"
brew list --formula > "$PREV_FORMULAS_FILE"
brew list --cask > "$PREV_CASKS_FILE"

# Esegui brew update
echo -e "${BLUE}Esecuzione di brew update...${NC}"
brew update

# Ottieni l'elenco dei pacchetti da aggiornare
echo -e "${BLUE}Controllo pacchetti da aggiornare...${NC}"
outdated_packages=$(brew outdated --verbose)

# Ottieni l'elenco dei pacchetti nuovi (confrontando con lo stato precedente)
echo -e "${BLUE}Controllo pacchetti nuovi...${NC}"
new_formulas=$(comm -13 "$PREV_FORMULAS_FILE" <(brew list --formula))
new_casks=$(comm -13 "$PREV_CASKS_FILE" <(brew list --cask))

# Verifica se ci sono pacchetti da aggiornare o nuovi
if [ -z "$outdated_packages" ] && [ -z "$new_formulas" ] && [ -z "$new_casks" ]; then
    echo -e "${GREEN}Nessun pacchetto da aggiornare e nessun pacchetto nuovo. Tutto è aggiornato.${NC}"
    rm -f "$PREV_FORMULAS_FILE" "$PREV_CASKS_FILE"
    exit 0
fi

# Mostra informazioni sui pacchetti da aggiornare
if [ -n "$outdated_packages" ]; then
    # Conta i pacchetti da aggiornare
    package_count=$(echo "$outdated_packages" | wc -l | tr -d ' ')
    echo -e "${YELLOW}Trovati $package_count pacchetti da aggiornare:${NC}"

    # Per ogni pacchetto da aggiornare, mostra le informazioni
    while IFS= read -r line; do
        # Estrai il nome del pacchetto (prima colonna)
        package_name=$(echo "$line" | awk '{print $1}')
        echo -e "${YELLOW}Versioni: $line${NC}"
        show_package_info "$package_name" "pacchetto da aggiornare"
    done <<< "$outdated_packages"
fi

# Mostra informazioni sui pacchetti nuovi (formule)
if [ -n "$new_formulas" ]; then
    formula_count=$(echo "$new_formulas" | wc -l | tr -d ' ')
    echo -e "${YELLOW}Trovate $formula_count nuove formule:${NC}"

    while IFS= read -r formula; do
        if [ -n "$formula" ]; then
            show_package_info "$formula" "nuova formula"
        fi
    done <<< "$new_formulas"
fi

# Mostra informazioni sui pacchetti nuovi (cask)
if [ -n "$new_casks" ]; then
    cask_count=$(echo "$new_casks" | wc -l | tr -d ' ')
    echo -e "${YELLOW}Trovati $cask_count nuovi cask:${NC}"

    while IFS= read -r cask; do
        if [ -n "$cask" ]; then
            show_package_info "$cask" "nuovo cask"
        fi
    done <<< "$new_casks"
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
rm -f "$PREV_FORMULAS_FILE" "$PREV_CASKS_FILE"

