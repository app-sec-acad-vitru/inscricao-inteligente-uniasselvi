# Banco centralizado — Inscrição Inteligente UNIASSELVI

## Arquitetura proposta
- Portal: GitHub Pages (mantido).
- Banco: Supabase PostgreSQL.
- Autenticação: Supabase Auth (e-mail e senha).
- Acesso público: somente inserção de inscrições.
- Acesso administrativo: leitura e atualização apenas para usuários cadastrados em `admin_users`.
- Documentos: não armazenar nesta primeira etapa; definir política de retenção, acesso e LGPD antes de habilitar upload centralizado.

## Etapa 1 — Criar o projeto Supabase
1. Acesse https://supabase.com/ e crie uma conta/projeto.
2. Crie um projeto chamado `inscricao-inteligente-uniasselvi`.
3. Escolha uma senha forte para o banco e guarde-a em local seguro.
4. Aguarde a criação do banco.

## Etapa 2 — Criar as tabelas e políticas
1. No painel Supabase, abra SQL Editor.
2. Abra o arquivo `supabase/schema.sql` deste repositório.
3. Copie todo o conteúdo para uma nova consulta SQL.
4. Execute e confirme que as tabelas `inscricoes` e `admin_users` foram criadas.

## Etapa 3 — Criar o usuário administrador
1. No Supabase, abra Authentication > Users.
2. Adicione o e-mail que será utilizado pelo responsável pelo painel.
3. Confirme/crie o usuário e copie seu UUID.
4. No SQL Editor, execute (substituindo o UUID):
   ```sql
   insert into public.admin_users (user_id, role)
   values ('UUID_DO_USUARIO', 'admin');
   ```
5. Não use PIN fixo no código como mecanismo real de segurança.

## Etapa 4 — Obter as chaves públicas do projeto
No painel do Supabase, abra Project Settings > API (ou Connect).
Separe:
- Project URL
- Publishable key (ou anon/public key, conforme a interface)

Essas duas informações serão configuradas no portal. A chave pública pode estar no frontend somente porque as políticas RLS limitam o que cada visitante pode fazer.

**Nunca compartilhe nem coloque no frontend a chave `service_role` ou qualquer segredo privado.**

## Etapa 5 — Integração do portal
Após receber Project URL e publishable/anon key, a integração será concluída no `index.html`:
- Salvar cada inscrição na tabela central `inscricoes`.
- Gerar e apresentar o protocolo retornado pelo banco.
- Autenticar o administrador por e-mail e senha.
- Consultar todas as inscrições com paginação, pesquisa e filtros.
- Exportar os resultados para CSV compatível com Excel.
- Manter uma opção de exportar os registros locais antigos para migração.

## Limitação do histórico atual
As inscrições antigas do protótipo estão em `localStorage` de cada navegador/dispositivo. O GitHub Pages não recebe esses registros. Para consolidá-las, será necessário exportar os dados de cada navegador onde foram realizadas e importar os arquivos na base central. Registros já apagados do armazenamento local não podem ser recuperados pelo repositório.

## Proteção de dados
O protótipo atual é público e não deve receber CPF ou dados reais até que a integração, autenticação, políticas RLS, aviso de privacidade, controles de acesso e processo de atendimento LGPD sejam revisados. A primeira versão centralizada não fará upload de documentos.
