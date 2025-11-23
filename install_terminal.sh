#!/bin/bash

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERREUR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Vérifier si le script est exécuté avec bash
if [ -z "$BASH_VERSION" ]; then
    print_error "Ce script doit être exécuté avec bash"
    exit 1
fi

print_info "🚀 Installation du Terminal Linux Style macOS"
echo ""

# Vérifier si Node.js est installé
print_info "Vérification de Node.js..."
if ! command -v node &> /dev/null; then
    print_warning "Node.js n'est pas installé"
    print_info "Installation de Node.js et npm..."
    
    # Détection de la distribution
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y nodejs npm
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y nodejs npm
    elif [ -f /etc/arch-release ]; then
        sudo pacman -S --noconfirm nodejs npm
    else
        print_error "Distribution non supportée. Installez Node.js manuellement."
        exit 1
    fi
    
    print_success "Node.js installé"
else
    print_success "Node.js déjà installé ($(node -v))"
fi

# Vérifier npm
if ! command -v npm &> /dev/null; then
    print_error "npm n'est pas installé"
    exit 1
fi

# Créer le dossier d'installation
INSTALL_DIR="$HOME/macos-terminal"
print_info "Création du répertoire d'installation: $INSTALL_DIR"

if [ -d "$INSTALL_DIR" ]; then
    print_warning "Le répertoire existe déjà"
    read -p "Voulez-vous le supprimer et réinstaller? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoYy]$ ]]; then
        rm -rf "$INSTALL_DIR"
        print_success "Ancien répertoire supprimé"
    else
        print_error "Installation annulée"
        exit 1
    fi
fi

# Créer le projet React
print_info "Création du projet React..."
npx create-react-app "$INSTALL_DIR" --template cra-template

cd "$INSTALL_DIR" || exit 1
print_success "Projet React créé"

# Installer les dépendances
print_info "Installation de lucide-react..."
npm install lucide-react

# Créer le composant Terminal
print_info "Création du composant Terminal..."
cat > src/App.js << 'EOF'
import React, { useState, useEffect, useRef } from 'react';
import { Terminal, Folder, File, Code, Trash2, Copy, Download, Settings, Maximize2, Minimize2, X } from 'lucide-react';

const MacOSTerminal = () => {
  const [input, setInput] = useState('');
  const [history, setHistory] = useState([
    { type: 'system', content: 'Terminal Linux v2.0 - Style macOS' },
    { type: 'system', content: 'Tapez "help" pour voir les commandes disponibles' },
  ]);
  const [currentDir, setCurrentDir] = useState('~');
  const [commandHistory, setCommandHistory] = useState([]);
  const [historyIndex, setHistoryIndex] = useState(-1);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [theme, setTheme] = useState('dark');
  const [showSettings, setShowSettings] = useState(false);
  const inputRef = useRef(null);
  const terminalRef = useRef(null);

  const fileSystem = {
    '~': ['Documents', 'Downloads', 'Pictures', 'projet.txt', 'script.sh'],
    '~/Documents': ['rapport.pdf', 'notes.md', 'presentation.pptx'],
    '~/Downloads': ['image.jpg', 'archive.zip'],
    '~/Pictures': ['photo1.jpg', 'photo2.png'],
  };

  useEffect(() => {
    if (terminalRef.current) {
      terminalRef.current.scrollTop = terminalRef.current.scrollHeight;
    }
  }, [history]);

  const commands = {
    help: () => ({
      type: 'output',
      content: `Commandes disponibles:
  help          - Afficher cette aide
  clear         - Effacer le terminal
  ls            - Lister les fichiers
  pwd           - Afficher le répertoire actuel
  cd [dir]      - Changer de répertoire
  cat [file]    - Afficher le contenu d'un fichier
  echo [text]   - Afficher du texte
  date          - Afficher la date
  whoami        - Afficher l'utilisateur
  uname         - Informations système
  tree          - Arborescence des fichiers
  history       - Historique des commandes
  theme [mode]  - Changer le thème (dark/light/blue)`,
    }),
    clear: () => {
      setHistory([]);
      return null;
    },
    ls: () => {
      const files = fileSystem[currentDir] || [];
      return {
        type: 'output',
        content: files.length > 0 ? files.join('  ') : 'Répertoire vide',
      };
    },
    pwd: () => ({
      type: 'output',
      content: currentDir,
    }),
    cd: (args) => {
      if (!args[0]) {
        setCurrentDir('~');
        return { type: 'output', content: 'Retour au répertoire personnel' };
      }
      const newDir = args[0] === '..' 
        ? currentDir.split('/').slice(0, -1).join('/') || '~'
        : currentDir === '~' 
          ? `~/${args[0]}`
          : `${currentDir}/${args[0]}`;
      
      if (fileSystem[newDir]) {
        setCurrentDir(newDir);
        return { type: 'output', content: `Changement vers ${newDir}` };
      }
      return { type: 'error', content: `cd: ${args[0]}: Répertoire introuvable` };
    },
    cat: (args) => {
      if (!args[0]) return { type: 'error', content: 'cat: fichier manquant' };
      const files = fileSystem[currentDir] || [];
      if (files.includes(args[0])) {
        return {
          type: 'output',
          content: `Contenu de ${args[0]}:\n\nCeci est un exemple de contenu.\nLorem ipsum dolor sit amet...`,
        };
      }
      return { type: 'error', content: `cat: ${args[0]}: Fichier introuvable` };
    },
    echo: (args) => ({
      type: 'output',
      content: args.join(' '),
    }),
    date: () => ({
      type: 'output',
      content: new Date().toLocaleString('fr-FR'),
    }),
    whoami: () => ({
      type: 'output',
      content: 'utilisateur',
    }),
    uname: () => ({
      type: 'output',
      content: 'Linux ubuntu 6.5.0-x86_64 GNU/Linux',
    }),
    tree: () => ({
      type: 'output',
      content: `${currentDir}
├── Documents/
│   ├── rapport.pdf
│   ├── notes.md
│   └── presentation.pptx
├── Downloads/
│   ├── image.jpg
│   └── archive.zip
├── Pictures/
│   ├── photo1.jpg
│   └── photo2.png
├── projet.txt
└── script.sh`,
    }),
    history: () => ({
      type: 'output',
      content: commandHistory.map((cmd, i) => `${i + 1}  ${cmd}`).join('\n'),
    }),
    theme: (args) => {
      const mode = args[0];
      if (['dark', 'light', 'blue'].includes(mode)) {
        setTheme(mode);
        return { type: 'output', content: `Thème changé en ${mode}` };
      }
      return { type: 'error', content: 'Thèmes disponibles: dark, light, blue' };
    },
  };

  const handleCommand = (cmd) => {
    const trimmed = cmd.trim();
    if (!trimmed) return;

    setCommandHistory([...commandHistory, trimmed]);
    setHistory([...history, { type: 'command', content: `${currentDir} $ ${trimmed}` }]);

    const [command, ...args] = trimmed.split(' ');
    const handler = commands[command];

    if (handler) {
      const result = handler(args);
      if (result) {
        setHistory((prev) => [...prev, result]);
      }
    } else {
      setHistory((prev) => [
        ...prev,
        { type: 'error', content: `${command}: commande introuvable. Tapez "help" pour l'aide.` },
      ]);
    }

    setInput('');
    setHistoryIndex(-1);
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') {
      handleCommand(input);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (historyIndex < commandHistory.length - 1) {
        const newIndex = historyIndex + 1;
        setHistoryIndex(newIndex);
        setInput(commandHistory[commandHistory.length - 1 - newIndex]);
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (historyIndex > 0) {
        const newIndex = historyIndex - 1;
        setHistoryIndex(newIndex);
        setInput(commandHistory[commandHistory.length - 1 - newIndex]);
      } else if (historyIndex === 0) {
        setHistoryIndex(-1);
        setInput('');
      }
    }
  };

  const themeStyles = {
    dark: {
      bg: 'bg-gray-900',
      text: 'text-gray-100',
      border: 'border-gray-700',
      titleBar: 'bg-gray-800',
      accent: 'text-green-400',
    },
    light: {
      bg: 'bg-gray-100',
      text: 'text-gray-900',
      border: 'border-gray-300',
      titleBar: 'bg-gray-200',
      accent: 'text-blue-600',
    },
    blue: {
      bg: 'bg-blue-950',
      text: 'text-blue-50',
      border: 'border-blue-800',
      titleBar: 'bg-blue-900',
      accent: 'text-cyan-400',
    },
  };

  const currentTheme = themeStyles[theme];

  return (
    <div className={`min-h-screen ${theme === 'dark' ? 'bg-gray-950' : theme === 'light' ? 'bg-gray-300' : 'bg-blue-950'} flex items-center justify-center p-8`}>
      <div className={`${isFullscreen ? 'w-full h-screen' : 'w-full max-w-4xl h-[600px]'} ${currentTheme.bg} rounded-2xl shadow-2xl overflow-hidden border ${currentTheme.border} transition-all duration-300`}>
        <div className={`${currentTheme.titleBar} px-4 py-3 flex items-center justify-between border-b ${currentTheme.border}`}>
          <div className="flex items-center space-x-2">
            <div className="flex space-x-2">
              <button className="w-3 h-3 rounded-full bg-red-500 hover:bg-red-600 transition"></button>
              <button className="w-3 h-3 rounded-full bg-yellow-500 hover:bg-yellow-600 transition" onClick={() => setIsFullscreen(!isFullscreen)}></button>
              <button className="w-3 h-3 rounded-full bg-green-500 hover:bg-green-600 transition" onClick={() => setIsFullscreen(!isFullscreen)}></button>
            </div>
            <Terminal className={`w-4 h-4 ml-4 ${currentTheme.text}`} />
            <span className={`text-sm font-medium ${currentTheme.text}`}>Terminal</span>
          </div>
          <div className="flex items-center space-x-2">
            <button onClick={() => setShowSettings(!showSettings)} className={`p-1.5 hover:bg-gray-700 rounded-lg transition ${currentTheme.text}`}>
              <Settings className="w-4 h-4" />
            </button>
            <button onClick={() => handleCommand('clear')} className={`p-1.5 hover:bg-gray-700 rounded-lg transition ${currentTheme.text}`}>
              <Trash2 className="w-4 h-4" />
            </button>
          </div>
        </div>

        {showSettings && (
          <div className={`${currentTheme.titleBar} px-4 py-3 border-b ${currentTheme.border} ${currentTheme.text}`}>
            <div className="flex items-center space-x-4">
              <span className="text-sm font-medium">Thème:</span>
              <button onClick={() => setTheme('dark')} className={`px-3 py-1 rounded-lg text-xs ${theme === 'dark' ? 'bg-green-600' : 'bg-gray-700'}`}>Dark</button>
              <button onClick={() => setTheme('light')} className={`px-3 py-1 rounded-lg text-xs ${theme === 'light' ? 'bg-blue-600' : 'bg-gray-700'}`}>Light</button>
              <button onClick={() => setTheme('blue')} className={`px-3 py-1 rounded-lg text-xs ${theme === 'blue' ? 'bg-cyan-600' : 'bg-gray-700'}`}>Blue</button>
            </div>
          </div>
        )}

        <div ref={terminalRef} className="p-4 h-[calc(100%-60px)] overflow-y-auto font-mono text-sm" onClick={() => inputRef.current?.focus()}>
          {history.map((line, i) => (
            <div key={i} className="mb-1">
              {line.type === 'command' && (
                <div className={currentTheme.accent}>{line.content}</div>
              )}
              {line.type === 'output' && (
                <pre className={`${currentTheme.text} whitespace-pre-wrap`}>{line.content}</pre>
              )}
              {line.type === 'error' && (
                <div className="text-red-500">{line.content}</div>
              )}
              {line.type === 'system' && (
                <div className="text-gray-500">{line.content}</div>
              )}
            </div>
          ))}
          
          <div className="flex items-center">
            <span className={currentTheme.accent}>{currentDir} $ </span>
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              className={`flex-1 ml-2 bg-transparent outline-none ${currentTheme.text}`}
              autoFocus
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default MacOSTerminal;
EOF

print_success "Composant Terminal créé"

# Créer un lanceur de bureau
print_info "Création du lanceur..."
cat > "$HOME/.local/share/applications/macos-terminal.desktop" << EOF
[Desktop Entry]
Name=Terminal macOS
Comment=Terminal Linux avec style macOS
Exec=bash -c "cd $INSTALL_DIR && npm start"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

print_success "Lanceur créé"

# Créer un script de lancement rapide
print_info "Création du script de lancement..."
cat > "$HOME/bin/macos-terminal" << EOF
#!/bin/bash
cd "$INSTALL_DIR" && npm start
EOF

mkdir -p "$HOME/bin"
chmod +x "$HOME/bin/macos-terminal"

# Vérifier si ~/bin est dans le PATH
if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    print_warning "Ajout de ~/bin au PATH"
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi

print_success "Script de lancement créé"

echo ""
print_success "✅ Installation terminée avec succès!"
echo ""
print_info "📌 Pour lancer le terminal:"
print_info "   1. Depuis le menu des applications: 'Terminal macOS'"
print_info "   2. Depuis la ligne de commande: macos-terminal"
print_info "   3. Ou directement: cd $INSTALL_DIR && npm start"
echo ""
print_info "🌐 Le terminal s'ouvrira dans votre navigateur à http://localhost:3000"
echo ""
read -p "Voulez-vous lancer le terminal maintenant? (o/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[OoYy]$ ]]; then
    print_info "Lancement du terminal..."
    cd "$INSTALL_DIR" && npm start
fi
