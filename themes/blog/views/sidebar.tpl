<!-- Target for toggling the sidebar `.sidebar-checkbox` is for regular
     styles, `#sidebar-checkbox` for behavior. -->
<input type="checkbox" class="sidebar-checkbox" id="sidebar-checkbox">

<!-- Toggleable sidebar -->
<div class="sidebar" id="sidebar">

    <div class="sidebar-item">
        <div class="search-box">
            <form action="/search">
                <span class="search-icon">&#9906;</span>
                <input id="search" name="q" placeholder="Search..." autocomplete="off" autocorrect="off" autocapitalize="off" type="search">
            </form>
         </div>
    </div>
    <div class="sidebar-item">
        {{!site_description}}
    </div>
    <nav class="sidebar-nav">
        <a class="sidebar-nav-item" href="{{!base_url}}/">Home</a>
        <a class="sidebar-nav-item">Foo</a>
        <a class="sidebar-nav-item">Bar</a>
    </nav>

    <div class="sidebar-item">
        <p>
        Powered by Sushy.
        </p>
    </div>
</div>