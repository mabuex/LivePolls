# LivePolls
A SwiftUI realtime polling app using Supabase as backend.

## SQL

```sql
create table if not exists public.polls (
  id uuid not null primary key default uuid_generate_v4(),
  name text not null,
  "createdAt" timestamp with time zone default timezone('utc' :: text, now()) not null,
  "updatedAt" timestamp with time zone default timezone('utc' :: text, now()) not null,
  "lastUpdatedOptionId" uuid
);  

create table if not exists public.options (
  id uuid not null primary key default uuid_generate_v4(),
  name text not null,
  count int4 not null default 0,
  "pollId" uuid not null
);

alter table public.polls add constraint "polls_lastUpdatedOptionId_fkey" foreign key ("lastUpdatedOptionId") references options (id) on delete set null;
alter table public.options add constraint "options_pollId_fkey" foreign key ("pollId") references polls (id) on delete cascade;

alter publication supabase_realtime add table public.polls;
alter publication supabase_realtime add table public.options;

create or replace function increment_count(id uuid) 
returns void as $$
  declare
    v_option_id alias for $1;
    v_option options;
  begin  
    update options o
    set count = count + 1
    where o.id = v_option_id
    returning * into v_option;

    update polls p
    set "lastUpdatedOptionId" = v_option_id, "updatedAt" = now()
    where p.id = v_option."pollId";
  end;
$$ 
language plpgsql;
```

## Credits

- [Coding with Alfian Realtime Polls App with Firebase](https://www.youtube.com/watch?v=OiPfDZTldMo)

## License

This repo is licensed under MIT.
