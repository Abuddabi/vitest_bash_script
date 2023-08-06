function vi_test() {
    local setupTestsFile="setupTests.js"
    
    function  setupTests() {
        local text=$(cat << END
import { expect, afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';
import matchers from '@testing-library/jest-dom/matchers';

expect.extend(matchers);

afterEach(() => {
    cleanup();
});
END
)
        echo "$text" > $setupTestsFile
    }

    function vite_config() {
        local filename="vite.config.js"
        local pattern="plugins: [react()]"
        local escaped_pattern=$(sed -e 's|\[|\\[|g; s|\]|\\]|g'  <<< "$pattern")
        local new_text=$(cat << END
    test: {
        globals: true,
        environment: 'jsdom',
        setupFiles: "'./$setupTestsFile'",
    }
END
)
        local escaped_new_text=$(echo "$new_text" | sed ':a;N;$!ba;s/\n/\\n/g')
        local replacement="$escaped_pattern,\n$escaped_new_text"

        sed -i "s|$escaped_pattern|$replacement|" $filename
    }

    function pkg_script() {
        local script_name="$1"
        local script_command="$2"

        if [[ -z "$script_name" || -z "$script_command" ]]; then
            echo "Usage: pkg_script <script_name> <script_command>"
            return 1
        fi

        local packagejson="package.json"

        if [[ ! -f "$packagejson" ]]; then
            echo "package.json not found in the current directory."
            return 1
        fi

        # Add the new script to package.json using jq
        jq ".scripts.\"$script_name\" = \"$script_command\"" "$packagejson" > temp.json
        mv temp.json "$packagejson"

        echo "\"$script_name\": \"$script_command\" added to package.json."
    }
    
    function eslint_config() {
        local eslintFile=".eslintrc.cjs"
        local pattern="env: { browser: true, es2020: true"
        local replacement='\"jest\/globals\": true'
        sed -i "s|\($pattern\)|\1, $replacement|" $eslintFile
    }

    echo -e "\033[1;34mInstalling Node dependencies...\033[0m\n" &&
    npm i -D vitest jsdom @testing-library/jest-dom @testing-library/react @testing-library/user-event &&
    setupTests &&
    vite_config &&
    pkg_script "test" "vitest" &&
    eslint_config
    echo -e "\n\033[1;32mDone!\033[0m\n"
}