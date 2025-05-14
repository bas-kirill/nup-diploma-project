create table if not exists datasets
(
    id                    bigserial   primary key,
    author_id             text        not null,
    author_name           text        not null,
    dataset_title         text        not null,
    dataset_ref           text        not null,
    dataset_size          text        not null,
    file_count            int,
    file_types            text,
    usability             decimal     not null,
    created_at            timestamptz not null,
    updated_at            timestamptz not null
);

--! truncate datasets restart identity;
