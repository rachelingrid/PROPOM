function d = localizar_conversor(P)
% Pasta 'octave' do Conversor JPG-CSV UTi320E (repositório separado).
% Usa P.pasta_conversor, se preenchido; senão procura uma pasta
% 'conversor-jpg-csv-uti320e*' (ex.: conversor-jpg-csv-uti320e-main, nome do
% ZIP baixado do GitHub) ao lado da pasta do PROPOM ou dentro dela.
  d = '';
  cands = {};
  if isfield(P, 'pasta_conversor') && ~isempty(P.pasta_conversor)
    cands{end+1} = P.pasta_conversor;
    cands{end+1} = fullfile(P.pasta_conversor, 'octave');
  end
  coleta = fileparts(fileparts(mfilename('fullpath')));   % .../PROPOM/coleta
  repo = fileparts(coleta);                               % .../PROPOM
  for base = {fileparts(repo), repo, coleta}
    l = dir(fullfile(base{1}, 'conversor-jpg-csv-uti320e*'));
    l = l([l.isdir]);
    for k = 1:numel(l)
      cands{end+1} = fullfile(base{1}, l(k).name, 'octave'); %#ok<AGROW>
    end
  end
  for k = 1:numel(cands)
    if isfile(fullfile(cands{k}, 'uti320e_jpg2csv.m')), d = cands{k}; return; end
  end
end
