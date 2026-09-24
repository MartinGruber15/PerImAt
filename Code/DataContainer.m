classdef DataContainer < handle

    properties (Access = private)
        contents = struct()
    end

    methods

        %% Constructor
        function obj = DataContainer(varargin)

            if nargin == 0
                return
            end

            if nargin == 1 && isstruct(varargin{1})
                obj.contents = varargin{1};
            else
                error('DataContainer:InvalidInput', ...
                    'Constructor expects either no input or one struct.');
            end
        end


        %% Dot access
        function value = subsref(obj, S)

            switch S(1).type

                case '.'

                    name = S(1).subs;

                    % Actual class property/method
                    if isprop(obj, name) || ismethod(obj, name)
                        value = builtin('subsref', obj, S);
                        return
                    end

                    % Existing dynamic field
                    if isfield(obj.contents, name)
                        value = obj.contents.(name);
                    else
                        % Automatically create nested container
                        value = DataContainer();
                        obj.contents.(name) = value;
                    end

                    % Process remaining indexing
                    if numel(S) > 1
                        value = subsref(value, S(2:end));
                    end

                otherwise
                    value = builtin('subsref', obj, S);
            end
        end


        %% Assignment
        function obj = subsasgn(obj, S, value)

            switch S(1).type

                case '.'

                    name = S(1).subs;

                    % Actual class property
                    if isprop(obj, name)
                        obj = builtin('subsasgn', obj, S, value);
                        return
                    end

                    % Simple assignment:
                    % obj.foo = value
                    if numel(S) == 1
                        obj.contents.(name) = value;
                        return
                    end

                    % Nested assignment:
                    % obj.foo.bar = value
                    if ~isfield(obj.contents, name)
                        obj.contents.(name) = DataContainer();
                    end

                    child = obj.contents.(name);

                    child = subsasgn(child, S(2:end), value);

                    obj.contents.(name) = child;

                otherwise
                    obj = builtin('subsasgn', obj, S, value);
            end
        end


        %% Convert recursively to struct
        function s = struct(obj)

            s = obj.contents;

            names = fieldnames(s);

            for k = 1:numel(names)

                value = s.(names{k});

                if isa(value, 'DataContainer')
                    s.(names{k}) = struct(value);
                end
            end
        end


        %% Display
        function disp(obj)

            fprintf('DataContainer with fields:\n');

            names = fieldnames(obj.contents);

            for k = 1:numel(names)
                fprintf('    %s\n', names{k});
            end

        end


        %% Check whether a field exists
        function tf = hasField(obj, name)

            tf = isfield(obj.contents, name);

        end


        %% Get field names
        function names = fieldnames(obj)

            names = fieldnames(obj.contents);

        end

    end
end
