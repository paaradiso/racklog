--- migration:up
ALTER TABLE weight_type RENAME TO equipment;

--- migration:down
ALTER TABLE equipment RENAME TO weight_type;

--- migration:end

