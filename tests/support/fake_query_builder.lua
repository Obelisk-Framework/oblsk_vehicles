--- Fake QueryBuilder for tests — stores data in a simple tables[table_name] = rows structure.
--- Supports: new(table), where(column, value), getSync(), delete()

return function(tables)
    local function makeMatcher(column, value)
        return function(row)
            return row[column] == value
        end
    end

    local function makeQueryBuilder(tableName)
        local matchers = {}

        return {
            where = function(self, column, value)
                table.insert(matchers, makeMatcher(column, value))
                return self
            end,

            getSync = function(self)
                local rows = tables[tableName] or {}
                local result = {}
                for _, row in ipairs(rows) do
                    local matches = true
                    for _, matcher in ipairs(matchers) do
                        if not matcher(row) then
                            matches = false
                            break
                        end
                    end
                    if matches then
                        table.insert(result, row)
                    end
                end
                return result
            end,

            delete = function(self)
                local rows = tables[tableName] or {}
                for i = #rows, 1, -1 do
                    local matches = true
                    for _, matcher in ipairs(matchers) do
                        if not matcher(rows[i]) then
                            matches = false
                            break
                        end
                    end
                    if matches then
                        table.remove(rows, i)
                    end
                end
            end,
        }
    end

    return {
        new = function(tableName)
            return makeQueryBuilder(tableName)
        end,
    }
end
