function gerar_site(raiz)
% GERAR_SITE  Roda todos os experimentos e monta a pagina estatica em <raiz>/site.
%
%   Cada pasta experimentos/NN_nome/ (pastas iniciadas por "_" sao ignoradas) deve ter:
%     analise.m    script que calcula tudo, salva figuras em pasta_saida e preenche R
%     pagina.html  texto da pagina com marcadores substituidos pelos resultados:
%                    {{val:nome}}           -> R.val.nome      (texto/numero formatado)
%                    {{tab:nome}}           -> R.tab.nome      (tabela HTML)
%                    {{fig:nome|legenda}}   -> R.fig.nome      (arquivo PNG em pasta_saida)
%     dados/       arquivos de dados (copiados para a pagina, para download)
%
%   O site funciona offline: abra site/index.html no navegador.

  saida = fullfile(raiz, 'site');
  if exist(saida, 'dir')
    confirm_recursive_rmdir(false, 'local');
    rmdir(saida, 's');
  end
  mkdir(saida);
  copyfile(fullfile(raiz, 'recursos', 'estilo.css'), saida);

  meta = metadados_execucao();
  lista = dir(fullfile(raiz, 'experimentos'));
  nomes = sort({lista([lista.isdir]).name});
  nomes = nomes(~cellfun(@(s) s(1) == '.' || s(1) == '_', nomes));

  % --- 1a passada: titulos (para a navegacao) -----------------------------
  titulos = cell(size(nomes));
  for k = 1:numel(nomes)
    titulos{k} = titulo_da_pagina(fullfile(raiz, 'experimentos', nomes{k}, 'pagina.html'), nomes{k});
  end
  nav = struct('id', nomes, 'titulo', titulos);

  % --- 2a passada: executa cada experimento -------------------------------
  cartoes = '';
  for k = 1:numel(nomes)
    id = nomes{k};
    pe = fullfile(raiz, 'experimentos', id);
    ps = fullfile(saida, id);
    mkdir(ps);
    printf('\n==================================================\n');
    printf(' Experimento %s\n', id);
    printf('==================================================\n');
    t0 = tic;
    try
      R = executar_experimento(pe, make_absolute_filename(ps));
      corpo = substituir_marcadores(fileread(fullfile(pe, 'pagina.html')), R, id);
      ok = true;
    catch err
      ok = false;
      printf('\n*** FALHA em %s: %s\n', id, err.message);
      for s = err.stack(:)'
        printf('    em %s (linha %d)\n', s.name, s.line);
      end
      R = struct('titulo', titulos{k}, 'resumo', '');
      corpo = sprintf(['<h1>%s</h1><div class="erro"><strong>A análise falhou nesta execução.</strong>' ...
                       '<pre>%s</pre></div>'], titulos{k}, html_esc(err.message));
    end
    printf('\n -> %s concluído em %.1f s\n', id, toc(t0));

    arq_dados = copiar_dados(pe, ps);
    corpo = [corpo secao_arquivos(ps, arq_dados) secao_codigo(raiz, pe, id, meta)];
    escrever(fullfile(ps, 'index.html'), pagina_html(titulos{k}, corpo, '../', nav, id, meta));
    cartoes = [cartoes cartao_indice(id, titulos{k}, R, ok)]; %#ok<AGROW>
  end

  % --- indice e biblioteca --------------------------------------------------
  intro = fileread(fullfile(raiz, 'recursos', 'inicio.html'));
  corpo = [intro '<section class="cartoes">' cartoes '</section>'];
  escrever(fullfile(saida, 'index.html'), pagina_html('Início', corpo, '', nav, '', meta));
  escrever(fullfile(saida, 'biblioteca.html'), ...
           pagina_html('Biblioteca comum', pagina_biblioteca(raiz, meta), '', nav, 'biblioteca', meta));
  printf('\nSite gerado em %s\n', saida);
end

% ===========================================================================
function meta = metadados_execucao()
  meta.data = datestr(now, 'dd/mm/yyyy HH:MM');
  meta.octave = OCTAVE_VERSION;
  meta.sha = getenv('GITHUB_SHA');
  meta.repo = getenv('GITHUB_REPOSITORY');
  meta.run = getenv('GITHUB_RUN_ID');
  meta.servidor = getenv('GITHUB_SERVER_URL');
  if isempty(meta.servidor), meta.servidor = 'https://github.com'; end
  meta.ci = ~isempty(meta.sha);
end

function t = titulo_da_pagina(arq, padrao)
  t = padrao;
  if exist(arq, 'file')
    tk = regexp(fileread(arq), '<h1[^>]*>(.*?)</h1>', 'tokens', 'once');
    if ~isempty(tk), t = regexprep(tk{1}, '<[^>]+>', ''); end
  end
end

function s = substituir_marcadores(s, R, id)
  campos = {'val', 'tab'};
  for c = campos
    nomes = regexp(s, ['\{\{' c{1} ':(\w+)\}\}'], 'tokens');
    for k = 1:numel(nomes)
      n = nomes{k}{1};
      if ~isfield(R, c{1}) || ~isfield(R.(c{1}), n)
        error('pagina.html de %s usa {{%s:%s}}, mas analise.m não definiu R.%s.%s', id, c{1}, n, c{1}, n);
      end
      v = R.(c{1}).(n);
      if isnumeric(v), v = fmt(v, 2); end
      s = strrep(s, ['{{' c{1} ':' n '}}'], v);
    end
  end
  [tok, ini, fim] = regexp(s, '\{\{fig:(\w+)\|([^}]*)\}\}', 'tokens', 'start', 'end');
  for k = numel(tok):-1:1
    n = tok{k}{1};
    if ~isfield(R, 'fig') || ~isfield(R.fig, n)
      error('pagina.html de %s usa {{fig:%s}}, mas analise.m não definiu R.fig.%s', id, n, n);
    end
    html = sprintf(['<figure><a href="%s"><img src="%s" alt="%s" loading="lazy"></a>' ...
                    '<figcaption>%s</figcaption></figure>'], R.fig.(n), R.fig.(n), ...
                   regexprep(tok{k}{2}, '<[^>]+>', ''), tok{k}{2});
    s = [s(1:ini(k)-1) html s(fim(k)+1:end)];
  end
end

function arqs = copiar_dados(pe, ps)
  arqs = {};
  pd = fullfile(pe, 'dados');
  if ~exist(pd, 'dir'), return; end
  mkdir(fullfile(ps, 'dados'));
  L = dir(pd);
  L = L(~[L.isdir]);
  for k = 1:numel(L)
    copyfile(fullfile(pd, L(k).name), fullfile(ps, 'dados'));
    arqs{end+1} = L(k).name; %#ok<AGROW>
  end
end

function s = secao_arquivos(ps, arq_dados)
  s = '<section class="arquivos"><h2>Arquivos para download</h2><div class="colunas">';
  s = [s '<div><h3>Dados de entrada</h3><ul>'];
  for k = 1:numel(arq_dados)
    s = [s sprintf('<li><a href="dados/%s">%s</a></li>', arq_dados{k}, arq_dados{k})]; %#ok<AGROW>
  end
  s = [s '</ul></div><div><h3>Resultados calculados</h3><ul>'];
  L = dir(fullfile(ps, '*.csv'));
  for k = 1:numel(L)
    s = [s sprintf('<li><a href="%s">%s</a></li>', L(k).name, L(k).name)]; %#ok<AGROW>
  end
  s = [s '</ul></div></div></section>'];
end

function s = secao_codigo(raiz, pe, id, meta)
  s = ['<section class="codigo"><h2>Código-fonte</h2>' ...
       '<p>Código exato que gerou esta página. As funções estatísticas comuns estão na ' ...
       '<a href="../biblioteca.html">biblioteca</a>.</p>'];
  arqs = listar_m(pe);
  for k = 1:numel(arqs)
    rel = strrep(arqs{k}(numel(pe)+2:end), '\', '/');
    s = [s bloco_codigo(arqs{k}, ['experimentos/' id '/' rel], meta, false)]; %#ok<AGROW>
  end
  s = [s '</section>'];
end

function s = pagina_biblioteca(raiz, meta)
  s = ['<h1>Biblioteca comum</h1><p class="lead">Funções em Octave puro (sem pacotes externos) ' ...
       'usadas por todos os experimentos. Validadas contra o R e o SciPy.</p>'];
  arqs = listar_m(fullfile(raiz, 'lib'));
  for k = 1:numel(arqs)
    [~, n, e] = fileparts(arqs{k});
    s = [s bloco_codigo(arqs{k}, ['lib/' n e], meta, false)]; %#ok<AGROW>
  end
end

function arqs = listar_m(pasta)
  arqs = {};
  L = dir(pasta);
  [~, ord] = sort(~strcmp({L.name}, 'analise.m'));   % analise.m primeiro
  L = L(ord);
  for k = 1:numel(L)
    if L(k).name(1) == '.', continue; end
    f = fullfile(pasta, L(k).name);
    if L(k).isdir
      if ~strcmp(L(k).name, 'dados'), arqs = [arqs listar_m(f)]; end %#ok<AGROW>
    elseif numel(L(k).name) > 2 && strcmp(L(k).name(end-1:end), '.m')
      arqs{end+1} = f; %#ok<AGROW>
    end
  end
end

function s = bloco_codigo(arq, rel, meta, aberto)
  txt = strrep(fileread(arq), sprintf('\r'), '');
  if ~isempty(txt) && txt(end) == sprintf('\n'), txt = txt(1:end-1); end
  linhas = strsplit(html_esc(txt), sprintf('\n'));
  corpo = sprintf('<span class="l">%s</span>\n', linhas{:});
  link = '';
  if meta.ci && ~isempty(meta.repo)
    link = sprintf(' <a class="gh" href="%s/%s/blob/%s/%s">ver no GitHub</a>', ...
                   meta.servidor, meta.repo, meta.sha, strrep(rel, ' ', '%20'));
  end
  ab = '';
  if aberto, ab = ' open'; end
  s = sprintf(['<details class="fonte"%s><summary><code>%s</code> <span class="n">%d linhas</span>%s</summary>' ...
               '<pre><code>%s</code></pre></details>'], ab, rel, numel(linhas), link, corpo);
end

function s = cartao_indice(id, titulo, R, ok)
  resumo = '';
  if isfield(R, 'resumo'), resumo = R.resumo; end
  dest = '';
  if ok && isfield(R, 'destaques')
    dest = '<dl class="destaques">';
    for k = 1:size(R.destaques, 1)
      dest = [dest sprintf('<div><dt>%s</dt><dd>%s</dd></div>', R.destaques{k, 1}, R.destaques{k, 2})]; %#ok<AGROW>
    end
    dest = [dest '</dl>'];
  elseif ~ok
    dest = '<p class="erro">A análise falhou nesta execução — veja a página do experimento.</p>';
  end
  num = regexp(id, '^\d+', 'match', 'once');
  s = sprintf(['<a class="cartao" href="%s/index.html"><span class="num">Experimento %s</span>' ...
               '<h2>%s</h2><p>%s</p>%s</a>'], id, num, titulo, resumo, dest);
end

function s = pagina_html(titulo, corpo, pre, nav, atual, meta)
  links = sprintf('<a href="%sindex.html"%s>Início</a>', pre, marca(isempty(atual)));
  for k = 1:numel(nav)
    num = regexp(nav(k).id, '^\d+', 'match', 'once');
    links = [links sprintf('<a href="%s%s/index.html"%s title="%s">%s</a>', pre, nav(k).id, ...
             marca(strcmp(atual, nav(k).id)), nav(k).titulo, ['Exp. ' num])]; %#ok<AGROW>
  end
  links = [links sprintf('<a href="%sbiblioteca.html"%s>Biblioteca</a>', pre, marca(strcmp(atual, 'biblioteca')))];

  if meta.ci
    sha = meta.sha(1:min(7, end));
    origem = sprintf(['commit <a href="%s/%s/commit/%s">%s</a> · ' ...
                      '<a href="%s/%s/actions/runs/%s">registro da execução</a>'], ...
                     meta.servidor, meta.repo, meta.sha, sha, meta.servidor, meta.repo, meta.run);
  else
    origem = 'execução local';
  end
  fuso = '';
  if meta.ci, fuso = ' (UTC)'; end
  rodape = sprintf(['Página gerada automaticamente pelo GNU Octave %s em %s%s · %s<br>' ...
                    '© Rachel Ingrid Pereira da Rocha Jannuzzi — PEB/COPPE/UFRJ. Todos os direitos reservados.'], ...
                   meta.octave, meta.data, fuso, origem);

  s = sprintf(['<!DOCTYPE html>\n<html lang="pt-BR">\n<head>\n<meta charset="utf-8">\n' ...
               '<meta name="viewport" content="width=device-width, initial-scale=1">\n' ...
               '<title>%s · ProPOM</title>\n<link rel="stylesheet" href="%sestilo.css">\n</head>\n<body>\n' ...
               '<header class="topo"><div class="faixa"><a class="marca" href="%sindex.html">ProPOM' ...
               '<span>Validação metrológica da cabine</span></a><nav>%s</nav></div></header>\n' ...
               '<main>\n%s\n</main>\n<footer>%s</footer>\n</body>\n</html>\n'], ...
              titulo, pre, pre, links, corpo, rodape);
end

function m = marca(c)
  if c, m = ' aria-current="page"'; else, m = ''; end
end

function escrever(arq, txt)
  fid = fopen(arq, 'w');
  fwrite(fid, txt);
  fclose(fid);
end
