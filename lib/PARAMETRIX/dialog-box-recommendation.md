remove the outer container and its scrollbar, we need to modify the HTML structure and CSS styles in your `ui_dialog_newui.txt` file. The current setup uses a `<body>` element that centers a `.dialog-container` div, and this div itself contains a scrollable `.content-area`. The outer scrollbar you're seeing likely comes from the `<body>` element attempting to accommodate the `.dialog-container` which might slightly exceed the SketchUp dialog's defined height, despite `scrollable: false` being set for the dialog itself.

The goal is to make the `<body>` element *itself* act as the main white, bordered, shadowed container, and then ensure its internal `content-area` handles the scrolling.

Here's how to modify the `ui_dialog_newui.txt` file:

**1. Modify the CSS `<style>` block:**

We will move the styling properties from `.dialog-container` directly to the `body` element, and remove some of the `body`'s current layout properties.

```css
    <style>
        /* ... (Keep existing utility CSS like .flex, .grid, etc.) ... */
        
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            
            /* Remove the outer gray background */
            /* background: #f0f0f0; */ 
            
            /* Remove centering and min-height as body will now be the main container */
            /* display: flex; */
            /* justify-content: center; */
            /* align-items: center; */
            /* min-height: 100vh; */
            /* padding: 20px; */

            /* Apply styles previously on .dialog-container to the body */
            background: #ffffff; /* White background for the main content */
            border-radius: 8px;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
            border: 1px solid #e5e7eb;
            
            /* Make body a flex container to manage its children (content-area and footer) */
            display: flex;
            flex-direction: column;
            overflow: hidden; /* Crucial: This prevents the body itself from scrolling */
            
            /* Set max dimensions for the body to fit within the SketchUp dialog window */
            /* These should align with UI::HtmlDialog.new width/height minus any desired margin */
            width: 100%; /* Take full width of the dialog */
            max-width: 400px; /* Limit the effective width of the content */
            max-height: calc(100vh - 20px); /* Adjust based on your dialog's actual height to ensure it fits. 
                                                If your dialog is fixed height, you might use '100%'.
                                                100vh - 20px accounts for a small margin if the dialog is too tall.*/
            margin: 10px; /* Add a small margin inside the SketchUp dialog window */
        }
        
        /* Remove .dialog-container styles as it will be removed from HTML */
        /*
        .dialog-container {
            width: 100%;
            max-width: 400px;
            background: #ffffff;
            border-radius: 8px;
            box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            max-height: 85vh;
            border: 1px solid #e5e7eb;
        }
        */

        .content-area {
            overflow-y: auto; /* Keep this for inner scrolling */
            padding: 12px;
            flex-grow: 1; /* Allow it to take up available vertical space */
        }
        
        /* ... (Keep other .setting-group, .dialog-title, .tooltip, .form-field styles) ... */

        /* Add styling for the footer group if you want it to have distinct background/padding from the main scrollable area */
        .dialog-footer {
            padding: 12px; /* Consistent padding with content-area */
            background: #f9fafb; /* Light background for the footer */
            border-top: 1px solid #e5e7eb; /* Separator line */
            border-bottom-left-radius: 8px; /* Match body border-radius */
            border-bottom-right-radius: 8px;
        }

    </style>
```

**2. Modify the HTML `<body>` structure:**

Remove the `<div class="dialog-container">` and its closing tag. The content previously inside it will now be direct children of `<body>`. The action buttons (Preview, Generate, Help) should remain separate from the scrollable `content-area` and will act as a fixed footer.

```html
<body>
    <!-- The main content area, which will be scrollable -->
    <div class="content-area">
        <!-- Preset Manager at Top -->
        <div class="setting-group">
            <div class="setting-group-title">Quick Presets</div>
            <div class="grid grid-cols-2 gap-2 mb-3">
                <select id="preset_dropdown" class="form-field rounded-lg" style="padding: 8px 12px; font-size: 13px;">
                    <option value="">Select a preset...</option>
                </select>
                <button id="load_preset_btn" class="px-3 py-2 bg-charcoal text-white rounded text-xs hover:bg-charcoal-light w-full">Load Preset</button>
            </div>
            <div class="grid grid-cols-2 gap-2">
                <input type="text" id="preset_name" placeholder="Preset Name" class="form-field rounded-lg" style="padding: 8px 12px; font-size: 13px; opacity: 0.7;" />
                <button id="save_preset_btn" class="px-3 py-2 bg-charcoal text-white rounded text-xs hover:bg-charcoal-light">Save Preset</button>
            </div>
        </div>

        <div class="dialog-title">PARAMETRIX v1.2-RAILS-FIX</div>
        <div style="text-align: center; font-size: 9px; color: #9ca3af; opacity: 0.7; margin-top: -8px; margin-bottom: 12px;">Build: RAILS-SEPARATE-#{Time.now.strftime('%Y%m%d-%H%M%S')}</div>
        
        <!-- Layout Tabs -->
        <div class="setting-group">
            <div class="setting-group-title">Layout Mode</div>
            <div class="flex gap-2 justify-center">
                <button id="multi_row_tab" class="px-4 py-2 text-xs font-medium tab-active transition" style="min-width: 100px;">Multi-Row</button>
                <button id="single_row_tab" class="px-4 py-2 text-xs font-medium tab-inactive transition" style="min-width: 100px;">Single-Row</button>
            </div>
        </div>
        <!-- Panel Dimensions & Joints -->
        <div class="setting-group">
            <div class="setting-group-title">Panel Dimensions & Joints (Units in #{unit_name})</div>
                <div class="grid grid-cols-2 gap-x-4 gap-y-3">
                    <div class="form-field col-span-2">
                        <label for="length" class="text-xs font-medium text-gray-600 mb-1 block">Panel Lengths (Semicolon-Separated List: e.g., 800;1000)</label>
                        <input type="text" id="length" value="#{@@length}" class="rounded-lg" />
                    </div>
                    <div class="form-field col-span-2">
                        <label for="height" class="text-xs font-medium text-gray-600 mb-1 block">Panel Heights (Semicolon-Separated List: e.g., 100;200)</label>
                        <input type="text" id="height" value="#{@@height}" class="rounded-lg" />
                    </div>
                    <div class="form-field">
                        <label for="thickness" class="text-xs font-medium text-gray-600 mb-1 block">Panel Thickness (#{unit_name})</label>
                        <input type="text" id="thickness" value="#{@@thickness}" class="rounded-lg" />
                    </div>
                    <div class="form-field col-span-2">
                        <div class="flex items-center mb-2">
                            <input type="checkbox" id="randomize_thickness" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{defined?(@@randomize_thickness) && @@randomize_thickness ? 'checked' : ''} />
                            <label for="randomize_thickness" class="text-sm text-gray-700">Randomize Panel Thickness (Stone Wall Effect)</label>
                        </div>
                        <div class="form-field" id="thickness_variation_field" style="#{defined?(@@randomize_thickness) && @@randomize_thickness ? '' : 'opacity: 0.5; pointer-events: none;'}">
                            <label for="thickness_variation" class="text-xs font-medium text-gray-600 mb-1 block">Thickness Variation (Min;Base;Max)</label>
                            <input type="text" id="thickness_variation" value="#{defined?(@@thickness_variation) ? @@thickness_variation : ''}" class="rounded-lg" placeholder="15;20;25" />
                        </div>
                    </div>
                    <div class="form-field">
                        <label for="joint_length" class="text-xs font-medium text-gray-600 mb-1 block">Horizontal Joints (mm)</label>
                        <input type="text" id="joint_length" value="#{@@joint_length}" class="rounded-lg" />
                    </div>
                    <div class="form-field">
                        <label for="joint_width" class="text-xs font-medium text-gray-600 mb-1 block">Vertical Joints (mm)</label>
                        <input type="text" id="joint_width" value="#{@@joint_width}" class="rounded-lg" />
                    </div>
                    <div class="form-field">
                        <label for="cavity_distance" class="text-xs font-medium text-gray-600 mb-1 block">Cavity Distance</label>
                        <input type="text" id="cavity_distance" value="#{@@cavity_distance}" />
                    </div>
                    <div class="form-field">
                        <label for="min_piece_length" class="text-xs font-medium text-gray-600 mb-1 block">Min Piece Length (#{unit_name})</label>
                        <input type="text" id="min_piece_length" value="#{@@enable_min_piece_length ? @@min_piece_length : 0}" />
                    </div>
                    <div class="form-field col-span-2">
                        <label for="color_name" class="text-xs font-medium text-gray-600 mb-1 block">Material Name</label>
                        <input type="text" id="color_name" value="#{@@color_name}" />
                    </div>
                </div>
            </div>

            <div class="setting-group">
                <div class="setting-group-title">Pattern, Placement & Randomization</div>
                <div class="grid grid-cols-2 gap-x-4 gap-y-3">
                    <div class="form-field">
                        <label for="pattern_type" class="text-xs font-medium text-gray-600 mb-1 block">Pattern Type</label>
                        <select id="pattern_type">
                            <option value="running_bond" #{@@pattern_type == 'running_bond' ? 'selected' : ''}>Running Bond</option>
                            <option value="stack_bond" #{@@pattern_type == 'stack_bond' ? 'selected' : ''}>Stack Bond</option>
                        </select>
                    </div>
                    <div class="form-field col-span-2">
                        <label for="layout_start_direction" class="text-xs font-medium text-gray-600 mb-1 block">
                            Layout Start Direction
                            <span class="tooltip">
                                <span class="help-icon">?</span>
                                <span class="tooltiptext">Controls where the layout pattern starts. Layout always builds upward and rightward from the start position.</span>
                            </span>
                        </label>
                        <select id="layout_start_direction">
                            <option value="center" #{@@layout_start_direction == 'center' ? 'selected' : ''}>Center</option>
                            <option value="top_left" #{@@layout_start_direction == 'top_left' ? 'selected' : ''}>Top Left</option>
                            <option value="top" #{@@layout_start_direction == 'top' ? 'selected' : ''}>Top</option>
                            <option value="top_right" #{@@layout_start_direction == 'top_right' ? 'selected' : ''}>Top Right</option>
                            <option value="left" #{@@layout_start_direction == 'left' ? 'selected' : ''}>Left</option>
                            <option value="right" #{@@layout_start_direction == 'right' ? 'selected' : ''}>Right</option>
                            <option value="bottom_left" #{@@layout_start_direction == 'bottom_left' ? 'selected' : ''}>Bottom Left</option>
                            <option value="bottom" #{@@layout_start_direction == 'bottom' ? 'selected' : ''}>Bottom</option>
                            <option value="bottom_right" #{@@layout_start_direction == 'bottom_right' ? 'selected' : ''}>Bottom Right</option>
                        </select>
                    </div>
                    <div class="form-field col-span-2" id="height_index_field">
                        <label for="height_index" class="text-xs font-medium text-gray-600 mb-1 block">
                            First Row Height Index
                            <span class="tooltip">
                                <span class="help-icon">?</span>
                                <span class="tooltiptext">Which height from your list to use for the bottom row (1-based). Example: if heights are [100,200,300] and index is 2, bottom row uses 200.</span>
                            </span>
                        </label>
                        <input type="text" id="height_index" value="#{@@start_row_height_index}" placeholder="1" />
                    </div>
                    <div class="col-span-2 flex items-center mt-1">
                        <input type="checkbox" id="randomize_lengths" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@randomize_lengths ? 'checked' : ''} />
                        <label for="randomize_lengths" class="text-sm text-gray-700">Randomize Panel Lengths</label>
                    </div>
                    <div class="col-span-2 flex items-center" id="randomize_heights_field">
                        <input type="checkbox" id="randomize_heights" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@randomize_heights ? 'checked' : ''} />
                        <label for="randomize_heights" class="text-sm text-gray-700">Randomize Panel Heights</label>
                    </div>
                </div>
            </div>

            <div class="setting-group">
                <div class="setting-group-title">Multi-Face & Corner Options</div>
                <div class="flex flex-col gap-2">
                    <div class="flex items-center">
                        <input type="checkbox" id="synchronize_patterns" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@synchronize_patterns ? 'checked' : ''} />
                        <label for="synchronize_patterns" class="text-sm text-gray-700">
                            Synchronize Patterns
                            <span class="tooltip">
                                <span class="help-icon">?</span>
                                <span class="tooltiptext">Creates seamless layout across all selected faces</span>
                            </span>
                        </label>
                    </div>
                    <div class="flex items-center">
                        <input type="checkbox" id="force_horizontal" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@force_horizontal_layout ? 'checked' : ''} />
                        <label for="force_horizontal" class="text-sm text-gray-700">
                            Force Horizontal Layout
                            <span class="tooltip">
                                <span class="help-icon">?</span>
                                <span class="tooltiptext">Ignores face tilt and forces horizontal orientation</span>
                            </span>
                        </label>
                    </div>
                    <div class="flex items-center">
                        <input type="checkbox" id="preserve_corners" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@preserve_corners ? 'checked' : ''} />
                        <label for="preserve_corners" class="text-sm text-gray-700">
                            Preserve Corners
                            <span class="tooltip">
                                <span class="help-icon">?</span>
                                <span class="tooltiptext">Generates unique corner pieces for better fit</span>
                            </span>
                        </label>
                    </div>
                </div>
            </div>

            <div class="setting-group">
                <div class="setting-group-title">Rail Settings</div>
                <div class="grid grid-cols-2 gap-x-4 gap-y-3">
                    <div class="flex flex-col">
                        <div class="flex items-center mb-2">
                            <input type="checkbox" id="enable_top_rail_multi" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@enable_top_rail ? 'checked' : ''} />
                            <label for="enable_top_rail_multi" class="text-sm font-semibold text-gray-700">Enable Top Rail</label>
                        </div>
                        <div class="form-field mb-2">
                            <label for="top_rail_thickness_multi" class="text-xs font-medium text-gray-600 mb-1 block">Thickness</label>
                            <input type="text" id="top_rail_thickness_multi" value="#{@@top_rail_thickness}" />
                        </div>
                        <div class="form-field">
                            <label for="top_rail_depth_multi" class="text-xs font-medium text-gray-600 mb-1 block">Depth</label>
                            <input type="text" id="top_rail_depth_multi" value="#{@@top_rail_depth}" />
                        </div>
                    </div>
                    <div class="flex flex-col">
                        <div class="flex items-center mb-2">
                            <input type="checkbox" id="enable_bottom_rail_multi" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@enable_bottom_rail ? 'checked' : ''} />
                            <label for="enable_bottom_rail_multi" class="text-sm font-semibold text-gray-700">Enable Bottom Rail</label>
                        </div>
                        <div class="form-field mb-2">
                            <label for="bottom_rail_thickness_multi" class="text-xs font-medium text-gray-600 mb-1 block">Thickness</label>
                            <input type="text" id="bottom_rail_thickness_multi" value="#{@@bottom_rail_thickness}" />
                        </div>
                        <div class="form-field">
                            <label for="bottom_rail_depth_multi" class="text-xs font-medium text-gray-600 mb-1 block">Depth</label>
                            <input type="text" id="bottom_rail_depth_multi" value="#{@@bottom_rail_depth}" />
                        </div>
                    </div>
                    <div class="flex flex-col">
                        <div class="flex items-center mb-2">
                            <input type="checkbox" id="enable_left_rail_multi" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@enable_left_rail ? 'checked' : ''} />
                            <label for="enable_left_rail_multi" class="text-sm font-semibold text-gray-700">Enable Left Rail</label>
                        </div>
                        <div class="form-field mb-2">
                            <label for="left_rail_thickness_multi" class="text-xs font-medium text-gray-600 mb-1 block">Thickness</label>
                            <input type="text" id="left_rail_thickness_multi" value="#{@@left_rail_thickness}" />
                        </div>
                        <div class="form-field">
                            <label for="left_rail_depth_multi" class="text-xs font-medium text-gray-600 mb-1 block">Depth</label>
                            <input type="text" id="left_rail_depth_multi" value="#{@@left_rail_depth}" />
                        </div>
                    </div>
                    <div class="flex flex-col">
                        <div class="flex items-center mb-2">
                            <input type="checkbox" id="enable_right_rail_multi" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@enable_right_rail ? 'checked' : ''} />
                            <label for="enable_right_rail_multi" class="text-sm font-semibold text-gray-700">Enable Right Rail</label>
                        </div>
                        <div class="form-field mb-2">
                            <label for="right_rail_thickness_multi" class="text-xs font-medium text-gray-600 mb-1 block">Thickness</label>
                            <input type="text" id="right_rail_thickness_multi" value="#{@@right_rail_thickness}" />
                        </div>
                        <div class="form-field">
                            <label for="right_rail_depth_multi" class="text-xs font-medium text-gray-600 mb-1 block">Depth</label>
                            <input type="text" id="right_rail_depth_multi" value="#{@@right_rail_depth}" />
                        </div>
                    </div>
                    <div class="col-span-2 flex items-center mt-2">
                        <input type="checkbox" id="split_rails_multi" class="mr-2 h-4 w-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500" #{@@split_rails ? 'checked' : ''} />
                        <label for="split_rails_multi" class="text-sm font-semibold text-gray-700">Split Rails into Pieces</label>
                    </div>
                    <div class="form-field col-span-2">
                        <label for="rail_material_name_multi" class="text-xs font-medium text-gray-600 mb-1 block">Rail Material Name</label>
                        <input type="text" id="rail_material_name_multi" value="#{@@rail_color_name}" />
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Action Buttons - now in their own footer div, a sibling of content-area -->
        <div class="dialog-footer">
            <div class="flex justify-center gap-3 w-full mb-2">
                <button id="previewBtn" class="px-3 py-2 bg-gray-600 text-white font-medium rounded shadow hover:bg-gray-700 transition text-xs flex-1">Preview</button>
                <button id="generateBtn" class="px-3 py-2 bg-charcoal text-white font-medium rounded shadow hover:bg-charcoal-light transition text-xs flex-1">Generate</button>
            </div>
            <div class="flex justify-center">
                <button id="helpBtn" class="px-2 py-1 bg-gray-500 text-white text-xs rounded hover:bg-gray-600 transition">ðŸ“– Help</button>
            </div>
        </div>

<script>
    // ... (Keep existing JavaScript code) ...
</script>
</body>
</html>
```

**Key Changes Explained:**

1.  **`<body>` as Main Container:**
    *   The `body` element now directly receives the white background, border-radius, shadow, and border that were previously on `.dialog-container`.
    *   `display: flex; flex-direction: column;` is applied to `body` so it correctly lays out its children (`.content-area` and `.dialog-footer`) vertically.
    *   `overflow: hidden;` on `body` explicitly tells the browser *not* to show scrollbars for the `body` itself, thus eliminating the outer scroll.
    *   `max-width: 400px;` and `max-height: calc(100vh - 20px);` (or similar) combined with `margin: 10px;` on the `body` ensure the entire `body` content fits snugly within the `UI::HtmlDialog`'s `width` and `height` properties (`420x580`). The `20px` in `calc()` is for `2 * 10px` body margin (top + bottom).
    *   Removed `background: #f0f0f0;`, `min-height: 100vh;`, `padding: 20px;`, and the centering `display: flex; justify-content: center; align-items: center;` from `body` as they are no longer needed and would cause extra space.

2.  **`.dialog-container` Removal:**
    *   The `<div class="dialog-container">` and its closing tag are completely removed from the HTML.

3.  **`.content-area` and `.dialog-footer`:**
    *   The scrollable content (all form fields and setting groups) remains within the `<div class="content-area">`, which retains `overflow-y: auto;` and `flex-grow: 1;` to handle internal scrolling.
    *   The action buttons are moved into a new `div` with class `dialog-footer` (or a similar descriptive class) that is a direct sibling of `content-area` under `body`. This ensures the buttons remain fixed at the bottom while `content-area` scrolls. Added some basic styling to `dialog-footer`.

By applying these changes, your dialog will appear as a single, self-contained white box within the SketchUp window, with an internal scrollbar for the settings if they overflow, and no outer container or scrollbar.