# Tradução dos trocadores de calor

O mod não oferece carregamento de arquivos PO. Os textos chineses estão diretamente na DLL.

`strings.json` mantém as traduções. O script principal `aplicar-traducoes.ps1` também chama `_build/aplicar-trocadores-ptbr.ps1`, que substitui somente instruções de texto `ldstr` e preserva a DLL original em `_backups`, identificada pelo SHA256.

Se uma atualização adicionar textos chineses desconhecidos, o script interrompe a aplicação sem sobrescrever a DLL. Atualize o mapa antes de reaplicar. Textos já traduzidos não são modificados novamente.

Para desfazer, restaure a DLL original correspondente à versão instalada a partir de `_backups`, ou reinstale este mod pela Steam. Reinicie o jogo após aplicar ou desfazer a tradução.
