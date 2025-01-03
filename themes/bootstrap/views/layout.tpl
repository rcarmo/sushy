<!DOCTYPE html>
<html lang="en" data-bs-theme="auto">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{!headers["title"]}}</title>
        <link rel="shortcut icon" href="/static/favicon.ico">
        <link rel="search" type="application/opensearchdescription+xml" title="{{site_name}}" href="/opensearch.xml"/>
<!--
        <link rel="canonical" href="<TODO: canonical URL>">
        <link rel="stylesheet" href="/static/css/syntax.css">
        <link rel="stylesheet" href="/static/css/site.css">
-->
        <!-- tint browser -->
        <meta name="theme-color" content="#712cf9">
        <meta name="msapplication-navbutton-color" content="#712cf9">
        <meta name="apple-mobile-web-app-status-bar-style" content="#712cf9">
        <link rel="stylesheet" href="/static/css/bootstrap.min.css">
        <link rel="stylesheet" href="/static/css/site.css">
        <script src="/static/js/site.js"></script>
        <!-- TODO: Favicons, OpenGraph -->

    </head>
    <body data-bs-spy="scroll" data-bs-target="#TableOfContents">
      <div class="skippy visually-hidden-focusable overflow-hidden">
          <div class="container-xl">
              <a class="d-inline-flex p-2 m-1" href="#content">Skip to main content</a>
              <a class="d-none d-md-inline-flex p-2 m-1" href="#bd-docs-nav">Skip to docs navigation</a>
          </div>
      </div>
      <!-- Baked in symbols, TODO: add app icons -->
      <svg xmlns="http://www.w3.org/2000/svg" class="d-none">
          <!-- Calendar (for Archives) -->
          <?xml version="1.0" encoding="UTF-8"?>
          <symbol id="cuttles" viewBox="0 0 4000 5500">
                <path d="m1742 2880c-133.56 17.17-416.18-73.058-255.23 161.54 64.782 285.3 385.3-121.05 255.23-161.54z" fill="#516681"/>
                <path d="m1360.9 199.21c-307.03 105.65-523.07 378.8-694.89 641.71-274.25 458.76-301.79 1030.3-136.6 1531.6 31.331 207.69-36.962 493.09 264.51 535.31 168.39 169.38-264.94 177.76-287.6 429.33-43.431 379.08 410.75 593.8 361.58 966.38-26.735 223.33-345.59 239.89-428.26 44.162-105.94-111.13 109.21-440-153.97-287.65-246.33 169.03-126.19 571.97 135.7 657.5 340.51 126.31 807.36 3.2867 943.04-360.39 114.58-268.2 58.645-578.25-111.72-816.11-32.477-240.1 192.8 134.7 226.17 170.29 164.5 280.18 108.87 622.31-40.029 895.41-109.24 270.93-99.558 649.11 160.52 830.99 222.73 99.287 372.68-302.41 78.429-227.41-217.85-209.02 156.39-361.39 261.47-520.96 215.42-225.68 381.93-552.65 263.31-866.71-21.776-90.397-208.19-428.79-0.8801-240.22 172.19 176.85 74.393 465.44 253.79 642.94 164.35 198.06 459.12 207.92 692.08 161.39 284.14-70.487 389.25-364.95 431.59-622.54 24.869-222.21 208.24-391.84 366.21-449.65-125.1-182.24-409.77-137.6-529.02 33.508-219.86 174.64-166.48 586.38-418.36 689.55-201.01-53.116-302.83-299.74-257.66-492.63 26.994-246.95-110.56-487.82-328.29-595.62 56.926-53.191 115.17-111.34 175.84-169 79.426-75.501 97.124-178.04 46.725-298.87 109.33-390.28 213.77-832.07 7.2688-1210.4-178.88-365.24-426.25-703.57-734.48-969.67-100.9-76.143-223.28-131.56-351.92-128.06m833.26 2174.5c-196.9 74.074-175.98 547.47 85.913 429.49 161.07-84.934 82.203-407.46-85.913-429.49zm-1526.2 32.843c-255.16-114.81-319.75 567.46-11.278 400.52 138.41-84.608 125.77-257.12 36.42-372.62m915.61 435.89c-140.76-6.7572-338.33 28.038-397.77 48.117 26.967 188.22 226.32 405.95 348.64 148.48 34.015-57.903 61.035-121.16 65.913-188.87m1864.4 393.91c-273.67 128.51-357.02 445.04-433.83 710.78-27.924 143.89-245.53 411.27-212.11 390.47 269.23 0.5851 438.38-260.06 462.3-504.3 26.671-227.87 175.48-448.74 345.69-557.88-38.688-44.844-107.34-49.652-162.05-39.061m-1695 76.843c27.69 100.08 334.59 258.9 159.51 63.018-40.98-42.974-101.04-63.314-159.51-63.018zm-473.66 345.69c104.87 183.38 128.43 403.11 100.88 611.04 197.12-180.23 50.415-460.13-100.88-611.04zm-182.56 254.18c2.179 308.4-206.81 605.33-481.45 734.27-305.25 135.31-560.1-248.07-475.84-521.88 34.258-196.2-252.66 126.92-166.97 251.38 67.268 306.28 461.6 385.96 714.56 267.34 270.41-48.816 452.63-327.16 432.09-593.97-9.1889-31.386 12.018-126.96-22.398-137.14m-1106.3 260.15-170.27-3137.2zm138.48 1.979c-365.51-4185-365.51-4185 0 0zm451.49 522.52-612.75-3530.6zm944.5 552.4c-92.223 36.784-285.04 91.408-73.199 131.51 72.646 13.307 224.1-121.03 73.199-131.51z" fill="#859dbb"/>
                <path d="m691.03 425.23c-159.53 85.63-508.51 273.64-257.2 460.62 125.11 259.77-304.21 317.32-351.88 539.15-80.997 212.79 291.78 285.59 71.413 496.97-129.6 169.96-65.243 435.74 158.58 481.62 87.424 70.742 121.72 428.81 250.99 335.69 27.91-276.08-97.139-531.31-126.31-809.43-78.728-646.75 235.45-1328.3 791.51-1671.3 250.95-134.83 576.18-90.812 771.25 121.06 305.61 315.11 586.7 679.16 722.32 1102.1 101.39 332.88-5.9671 677.56-87.992 1001.9 76.896 173.58-89.493 305.65 95.75 219.47 50.908-161.71 54.447-306.42 243.69-346.6 341.1-195.31-228.76-554.27 61.454-701.18 198.29-207.94-101.94-403.6-253.05-519.12-256.2-171.84 196.36-341.52-36.958-519.68-208.11-132-409.49-278.75-619.88-407.88-312.88-157.61-702.27-223.65-1021.6-44.855-146.8 71.245-280.38 165.94-412.1 261.42zm2993.5 2820.9c-267.01 124.7-353.07 431.63-427.38 691.52-62.653 163.44-195.35 380.45-211.25 408.86 286.61 3.2073 435.01-283.84 462-532.87 20.792-219.72 195.35-430.14 334.09-532.35-42.61-36.846-104.75-34.527-157.46-35.159zm-1695 76.843c27.69 100.08 334.59 258.9 159.51 63.018-40.98-42.974-101.04-63.314-159.51-63.018zm-473.66 345.69c104.87 183.38 128.43 403.11 100.88 611.04 197.12-180.23 50.415-460.13-100.88-611.04zm-182.56 254.18c1.6512 309.88-209.13 610.19-487.38 736.47-306.02 129.43-543.82-253.11-468.89-523.17 32.757-198.12-253.28 125.99-167.99 250.48 67.338 307.66 461.43 386.24 715.16 266.98 270.23-48.652 451.95-327.18 431.49-593.62-9.1886-31.386 12.019-126.96-22.397-137.14zm428.21 1337c-92.223 36.784-285.04 91.408-73.199 131.51 72.646 13.307 224.1-121.03 73.199-131.51z" fill="#c8e4f3"/>
                <path d="m2403.8 2344.5c-211.8 51.601-202.66 549.63 71.432 434.19 169.78-86.261 82.256-386.4-71.432-434.19zm-1596.3 6.7878c-284.29 56.095-191.21 680.71 102.38 383.87 93.585-104.93 33.929-356.67-102.38-383.87zm1563.5 50.501c-176.37 163.09 141.02 232.69 57.502 27.25-15.22-29.376-28.116-35.957-57.502-27.25zm-1591.2-3.8443c-187.28 73.32 39.706 332.73 72.307 92.439 13.759-66.149-35.653-108.11-72.307-92.439zm974.55 445.14c-56.142 8.726-509.04-57.127-331.04 101.01 9.9143 240.32 282.23 305.81 351.91 59.684 14.965-61.208 123.67-201.84-20.863-160.7zm-13.415 38.936c-127.38 22.264-426.9-69.42-241.39 170.73 68.924 255.95 363.98-135.17 241.39-170.73z" style="fill:#000000 !important;"/>
                <path d="m785.66 2397.5c-153.69 25.895-35.211 301.79 50.98 90.382 29.543-36.588-4.9417-99.935-50.98-90.382zm1592.3 0.461c-225.76 223.19 211.98 183.04 0 0z" fill="#ffffff"/>
          </symbol>
          <symbol id="calendar3" viewBox="0 0 16 16">
            <path d="M14 0H2a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2M1 3.857C1 3.384 1.448 3 2 3h12c.552 0 1 .384 1 .857v10.286c0 .473-.448.857-1 .857H2c-.552 0-1-.384-1-.857z"/>
            <path d="M6.5 7a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2m-9 3a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2m-9 3a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2m3 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2"/>
          </symbol>
          <symbol id="circle" viewBox="0 0 16 16">
            <path d="M8 15A7 7 0 1 1 8 1a7 7 0 0 1 0 14m0 1A8 8 0 1 0 8 0a8 8 0 0 0 0 16"/>
          </symbol>
          <symbol id="arrow-right" viewBox="0 0 16 16">
              <path fill-rule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/>
          </symbol>
          <symbol id="book-half" viewBox="0 0 16 16">
              <path d="M8.5 2.687c.654-.689 1.782-.886 3.112-.752 1.234.124 2.503.523 3.388.893v9.923c-.918-.35-2.107-.692-3.287-.81-1.094-.111-2.278-.039-3.213.492V2.687zM8 1.783C7.015.936 5.587.81 4.287.94c-1.514.153-3.042.672-3.994 1.105A.5.5 0 0 0 0 2.5v11a.5.5 0 0 0 .707.455c.882-.4 2.303-.881 3.68-1.02 1.409-.142 2.59.087 3.223.877a.5.5 0 0 0 .78 0c.633-.79 1.814-1.019 3.222-.877 1.378.139 2.8.62 3.681 1.02A.5.5 0 0 0 16 13.5v-11a.5.5 0 0 0-.293-.455c-.952-.433-2.48-.952-3.994-1.105C10.413.809 8.985.936 8 1.783z"/>
          </symbol>
          <symbol id="box-seam" viewBox="0 0 16 16">
              <path d="M8.186 1.113a.5.5 0 0 0-.372 0L1.846 3.5l2.404.961L10.404 2l-2.218-.887zm3.564 1.426L5.596 5 8 5.961 14.154 3.5l-2.404-.961zm3.25 1.7-6.5 2.6v7.922l6.5-2.6V4.24zM7.5 14.762V6.838L1 4.239v7.923l6.5 2.6zM7.443.184a1.5 1.5 0 0 1 1.114 0l7.129 2.852A.5.5 0 0 1 16 3.5v8.662a1 1 0 0 1-.629.928l-7.185 2.874a.5.5 0 0 1-.372 0L.63 13.09a1 1 0 0 1-.63-.928V3.5a.5.5 0 0 1 .314-.464L7.443.184z"/>
          </symbol>
          <symbol id="braces" viewBox="0 0 16 16">
              <path d="M2.114 8.063V7.9c1.005-.102 1.497-.615 1.497-1.6V4.503c0-1.094.39-1.538 1.354-1.538h.273V2h-.376C3.25 2 2.49 2.759 2.49 4.352v1.524c0 1.094-.376 1.456-1.49 1.456v1.299c1.114 0 1.49.362 1.49 1.456v1.524c0 1.593.759 2.352 2.372 2.352h.376v-.964h-.273c-.964 0-1.354-.444-1.354-1.538V9.663c0-.984-.492-1.497-1.497-1.6zM13.886 7.9v.163c-1.005.103-1.497.616-1.497 1.6v1.798c0 1.094-.39 1.538-1.354 1.538h-.273v.964h.376c1.613 0 2.372-.759 2.372-2.352v-1.524c0-1.094.376-1.456 1.49-1.456V7.332c-1.114 0-1.49-.362-1.49-1.456V4.352C13.51 2.759 12.75 2 11.138 2h-.376v.964h.273c.964 0 1.354.444 1.354 1.538V6.3c0 .984.492 1.497 1.497 1.6z"/>
          </symbol>
          <symbol id="braces-asterisk" viewBox="0 0 16 16">
              <path fill-rule="evenodd" d="M1.114 8.063V7.9c1.005-.102 1.497-.615 1.497-1.6V4.503c0-1.094.39-1.538 1.354-1.538h.273V2h-.376C2.25 2 1.49 2.759 1.49 4.352v1.524c0 1.094-.376 1.456-1.49 1.456v1.299c1.114 0 1.49.362 1.49 1.456v1.524c0 1.593.759 2.352 2.372 2.352h.376v-.964h-.273c-.964 0-1.354-.444-1.354-1.538V9.663c0-.984-.492-1.497-1.497-1.6ZM14.886 7.9v.164c-1.005.103-1.497.616-1.497 1.6v1.798c0 1.094-.39 1.538-1.354 1.538h-.273v.964h.376c1.613 0 2.372-.759 2.372-2.352v-1.524c0-1.094.376-1.456 1.49-1.456v-1.3c-1.114 0-1.49-.362-1.49-1.456V4.352C14.51 2.759 13.75 2 12.138 2h-.376v.964h.273c.964 0 1.354.444 1.354 1.538V6.3c0 .984.492 1.497 1.497 1.6ZM7.5 11.5V9.207l-1.621 1.621-.707-.707L6.792 8.5H4.5v-1h2.293L5.172 5.879l.707-.707L7.5 6.792V4.5h1v2.293l1.621-1.621.707.707L9.208 7.5H11.5v1H9.207l1.621 1.621-.707.707L8.5 9.208V11.5h-1Z"/>
          </symbol>
          <symbol id="check2" viewBox="0 0 16 16">
              <path d="M13.854 3.646a.5.5 0 0 1 0 .708l-7 7a.5.5 0 0 1-.708 0l-3.5-3.5a.5.5 0 1 1 .708-.708L6.5 10.293l6.646-6.647a.5.5 0 0 1 .708 0z"/>
          </symbol>
          <symbol id="chevron-expand" viewBox="0 0 16 16">
              <path fill-rule="evenodd" d="M3.646 9.146a.5.5 0 0 1 .708 0L8 12.793l3.646-3.647a.5.5 0 0 1 .708.708l-4 4a.5.5 0 0 1-.708 0l-4-4a.5.5 0 0 1 0-.708zm0-2.292a.5.5 0 0 0 .708 0L8 3.207l3.646 3.647a.5.5 0 0 0 .708-.708l-4-4a.5.5 0 0 0-.708 0l-4 4a.5.5 0 0 0 0 .708z"/>
          </symbol>
          <symbol id="circle-half" viewBox="0 0 16 16">
              <path d="M8 15A7 7 0 1 0 8 1v14zm0 1A8 8 0 1 1 8 0a8 8 0 0 1 0 16z"/>
          </symbol>
          <symbol id="clipboard" viewBox="0 0 16 16">
              <path d="M4 1.5H3a2 2 0 0 0-2 2V14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V3.5a2 2 0 0 0-2-2h-1v1h1a1 1 0 0 1 1 1V14a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V3.5a1 1 0 0 1 1-1h1v-1z"/>
              <path d="M9.5 1a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-3a.5.5 0 0 1-.5-.5v-1a.5.5 0 0 1 .5-.5h3zm-3-1A1.5 1.5 0 0 0 5 1.5v1A1.5 1.5 0 0 0 6.5 4h3A1.5 1.5 0 0 0 11 2.5v-1A1.5 1.5 0 0 0 9.5 0h-3z"/>
          </symbol>
          <symbol id="code" viewBox="0 0 16 16">
              <path d="M5.854 4.854a.5.5 0 1 0-.708-.708l-3.5 3.5a.5.5 0 0 0 0 .708l3.5 3.5a.5.5 0 0 0 .708-.708L2.707 8l3.147-3.146zm4.292 0a.5.5 0 0 1 .708-.708l3.5 3.5a.5.5 0 0 1 0 .708l-3.5 3.5a.5.5 0 0 1-.708-.708L13.293 8l-3.147-3.146z"/>
          </symbol>
          <symbol id="file-earmark-richtext" viewBox="0 0 16 16">
              <path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5zm-3 0A1.5 1.5 0 0 1 9.5 3V1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4.5h-2z"/>
              <path d="M4.5 12.5A.5.5 0 0 1 5 12h3a.5.5 0 0 1 0 1H5a.5.5 0 0 1-.5-.5zm0-2A.5.5 0 0 1 5 10h6a.5.5 0 0 1 0 1H5a.5.5 0 0 1-.5-.5zm1.639-3.708 1.33.886 1.854-1.855a.25.25 0 0 1 .289-.047l1.888.974V8.5a.5.5 0 0 1-.5.5H5a.5.5 0 0 1-.5-.5V8s1.54-1.274 1.639-1.208zM6.25 6a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5z"/>
          </symbol>
          <symbol id="globe2" viewBox="0 0 16 16">
              <path d="M0 8a8 8 0 1 1 16 0A8 8 0 0 1 0 8zm7.5-6.923c-.67.204-1.335.82-1.887 1.855-.143.268-.276.56-.395.872.705.157 1.472.257 2.282.287V1.077zM4.249 3.539c.142-.384.304-.744.481-1.078a6.7 6.7 0 0 1 .597-.933A7.01 7.01 0 0 0 3.051 3.05c.362.184.763.349 1.198.49zM3.509 7.5c.036-1.07.188-2.087.436-3.008a9.124 9.124 0 0 1-1.565-.667A6.964 6.964 0 0 0 1.018 7.5h2.49zm1.4-2.741a12.344 12.344 0 0 0-.4 2.741H7.5V5.091c-.91-.03-1.783-.145-2.591-.332zM8.5 5.09V7.5h2.99a12.342 12.342 0 0 0-.399-2.741c-.808.187-1.681.301-2.591.332zM4.51 8.5c.035.987.176 1.914.399 2.741A13.612 13.612 0 0 1 7.5 10.91V8.5H4.51zm3.99 0v2.409c.91.03 1.783.145 2.591.332.223-.827.364-1.754.4-2.741H8.5zm-3.282 3.696c.12.312.252.604.395.872.552 1.035 1.218 1.65 1.887 1.855V11.91c-.81.03-1.577.13-2.282.287zm.11 2.276a6.696 6.696 0 0 1-.598-.933 8.853 8.853 0 0 1-.481-1.079 8.38 8.38 0 0 0-1.198.49 7.01 7.01 0 0 0 2.276 1.522zm-1.383-2.964A13.36 13.36 0 0 1 3.508 8.5h-2.49a6.963 6.963 0 0 0 1.362 3.675c.47-.258.995-.482 1.565-.667zm6.728 2.964a7.009 7.009 0 0 0 2.275-1.521 8.376 8.376 0 0 0-1.197-.49 8.853 8.853 0 0 1-.481 1.078 6.688 6.688 0 0 1-.597.933zM8.5 11.909v3.014c.67-.204 1.335-.82 1.887-1.855.143-.268.276-.56.395-.872A12.63 12.63 0 0 0 8.5 11.91zm3.555-.401c.57.185 1.095.409 1.565.667A6.963 6.963 0 0 0 14.982 8.5h-2.49a13.36 13.36 0 0 1-.437 3.008zM14.982 7.5a6.963 6.963 0 0 0-1.362-3.675c-.47.258-.995.482-1.565.667.248.92.4 1.938.437 3.008h2.49zM11.27 2.461c.177.334.339.694.482 1.078a8.368 8.368 0 0 0 1.196-.49 7.01 7.01 0 0 0-2.275-1.52c.218.283.418.597.597.932zm-.488 1.343a7.765 7.765 0 0 0-.395-.872C9.835 1.897 9.17 1.282 8.5 1.077V4.09c.81-.03 1.577-.13 2.282-.287z"/>
          </symbol>
          <symbol id="grid-fill" viewBox="0 0 16 16">
              <path d="M1 2.5A1.5 1.5 0 0 1 2.5 1h3A1.5 1.5 0 0 1 7 2.5v3A1.5 1.5 0 0 1 5.5 7h-3A1.5 1.5 0 0 1 1 5.5v-3zm8 0A1.5 1.5 0 0 1 10.5 1h3A1.5 1.5 0 0 1 15 2.5v3A1.5 1.5 0 0 1 13.5 7h-3A1.5 1.5 0 0 1 9 5.5v-3zm-8 8A1.5 1.5 0 0 1 2.5 9h3A1.5 1.5 0 0 1 7 10.5v3A1.5 1.5 0 0 1 5.5 15h-3A1.5 1.5 0 0 1 1 13.5v-3zm8 0A1.5 1.5 0 0 1 10.5 9h3a1.5 1.5 0 0 1 1.5 1.5v3a1.5 1.5 0 0 1-1.5 1.5h-3A1.5 1.5 0 0 1 9 13.5v-3z"/>
          </symbol>
          <symbol id="lightning-charge-fill" viewBox="0 0 16 16">
              <path d="M11.251.068a.5.5 0 0 1 .227.58L9.677 6.5H13a.5.5 0 0 1 .364.843l-8 8.5a.5.5 0 0 1-.842-.49L6.323 9.5H3a.5.5 0 0 1-.364-.843l8-8.5a.5.5 0 0 1 .615-.09z"/>
          </symbol>
          <symbol id="list" viewBox="0 0 16 16">
              <path fill-rule="evenodd" d="M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5z"/>
          </symbol>
          <symbol id="magic" viewBox="0 0 16 16">
              <path d="M9.5 2.672a.5.5 0 1 0 1 0V.843a.5.5 0 0 0-1 0v1.829Zm4.5.035A.5.5 0 0 0 13.293 2L12 3.293a.5.5 0 1 0 .707.707L14 2.707ZM7.293 4A.5.5 0 1 0 8 3.293L6.707 2A.5.5 0 0 0 6 2.707L7.293 4Zm-.621 2.5a.5.5 0 1 0 0-1H4.843a.5.5 0 1 0 0 1h1.829Zm8.485 0a.5.5 0 1 0 0-1h-1.829a.5.5 0 0 0 0 1h1.829ZM13.293 10A.5.5 0 1 0 14 9.293L12.707 8a.5.5 0 1 0-.707.707L13.293 10ZM9.5 11.157a.5.5 0 0 0 1 0V9.328a.5.5 0 0 0-1 0v1.829Zm1.854-5.097a.5.5 0 0 0 0-.706l-.708-.708a.5.5 0 0 0-.707 0L8.646 5.94a.5.5 0 0 0 0 .707l.708.708a.5.5 0 0 0 .707 0l1.293-1.293Zm-3 3a.5.5 0 0 0 0-.706l-.708-.708a.5.5 0 0 0-.707 0L.646 13.94a.5.5 0 0 0 0 .707l.708.708a.5.5 0 0 0 .707 0L8.354 9.06Z"/>
          </symbol>
          <symbol id="menu-button-wide-fill" viewBox="0 0 16 16">
              <path d="M1.5 0A1.5 1.5 0 0 0 0 1.5v2A1.5 1.5 0 0 0 1.5 5h13A1.5 1.5 0 0 0 16 3.5v-2A1.5 1.5 0 0 0 14.5 0h-13zm1 2h3a.5.5 0 0 1 0 1h-3a.5.5 0 0 1 0-1zm9.927.427A.25.25 0 0 1 12.604 2h.792a.25.25 0 0 1 .177.427l-.396.396a.25.25 0 0 1-.354 0l-.396-.396zM0 8a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V8zm1 3v2a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-2H1zm14-1V8a1 1 0 0 0-1-1H2a1 1 0 0 0-1 1v2h14zM2 8.5a.5.5 0 0 1 .5-.5h9a.5.5 0 0 1 0 1h-9a.5.5 0 0 1-.5-.5zm0 4a.5.5 0 0 1 .5-.5h6a.5.5 0 0 1 0 1h-6a.5.5 0 0 1-.5-.5z"/>
          </symbol>
          <symbol id="moon-stars-fill" viewBox="0 0 16 16">
              <path d="M6 .278a.768.768 0 0 1 .08.858 7.208 7.208 0 0 0-.878 3.46c0 4.021 3.278 7.277 7.318 7.277.527 0 1.04-.055 1.533-.16a.787.787 0 0 1 .81.316.733.733 0 0 1-.031.893A8.349 8.349 0 0 1 8.344 16C3.734 16 0 12.286 0 7.71 0 4.266 2.114 1.312 5.124.06A.752.752 0 0 1 6 .278z"/>
              <path d="M10.794 3.148a.217.217 0 0 1 .412 0l.387 1.162c.173.518.579.924 1.097 1.097l1.162.387a.217.217 0 0 1 0 .412l-1.162.387a1.734 1.734 0 0 0-1.097 1.097l-.387 1.162a.217.217 0 0 1-.412 0l-.387-1.162A1.734 1.734 0 0 0 9.31 6.593l-1.162-.387a.217.217 0 0 1 0-.412l1.162-.387a1.734 1.734 0 0 0 1.097-1.097l.387-1.162zM13.863.099a.145.145 0 0 1 .274 0l.258.774c.115.346.386.617.732.732l.774.258a.145.145 0 0 1 0 .274l-.774.258a1.156 1.156 0 0 0-.732.732l-.258.774a.145.145 0 0 1-.274 0l-.258-.774a1.156 1.156 0 0 0-.732-.732l-.774-.258a.145.145 0 0 1 0-.274l.774-.258c.346-.115.617-.386.732-.732L13.863.1z"/>
          </symbol>
          <symbol id="palette2" viewBox="0 0 16 16">
              <path d="M0 .5A.5.5 0 0 1 .5 0h5a.5.5 0 0 1 .5.5v5.277l4.147-4.131a.5.5 0 0 1 .707 0l3.535 3.536a.5.5 0 0 1 0 .708L10.261 10H15.5a.5.5 0 0 1 .5.5v5a.5.5 0 0 1-.5.5H3a2.99 2.99 0 0 1-2.121-.879A2.99 2.99 0 0 1 0 13.044m6-.21 7.328-7.3-2.829-2.828L6 7.188v5.647zM4.5 13a1.5 1.5 0 1 0-3 0 1.5 1.5 0 0 0 3 0zM15 15v-4H9.258l-4.015 4H15zM0 .5v12.495V.5z"/>
              <path d="M0 12.995V13a3.07 3.07 0 0 0 0-.005z"/>
          </symbol>
          <symbol id="plugin" viewBox="0 0 16 16">
              <path fill-rule="evenodd" d="M1 8a7 7 0 1 1 2.898 5.673c-.167-.121-.216-.406-.002-.62l1.8-1.8a3.5 3.5 0 0 0 4.572-.328l1.414-1.415a.5.5 0 0 0 0-.707l-.707-.707 1.559-1.563a.5.5 0 1 0-.708-.706l-1.559 1.562-1.414-1.414 1.56-1.562a.5.5 0 1 0-.707-.706l-1.56 1.56-.707-.706a.5.5 0 0 0-.707 0L5.318 5.975a3.5 3.5 0 0 0-.328 4.571l-1.8 1.8c-.58.58-.62 1.6.121 2.137A8 8 0 1 0 0 8a.5.5 0 0 0 1 0Z"/>
          </symbol>
          <symbol id="plus" viewBox="0 0 16 16">
              <path d="M8 4a.5.5 0 0 1 .5.5v3h3a.5.5 0 0 1 0 1h-3v3a.5.5 0 0 1-1 0v-3h-3a.5.5 0 0 1 0-1h3v-3A.5.5 0 0 1 8 4z"/>
          </symbol>
          <symbol id="sun-fill" viewBox="0 0 16 16">
              <path d="M8 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM8 0a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 0zm0 13a.5.5 0 0 1 .5.5v2a.5.5 0 0 1-1 0v-2A.5.5 0 0 1 8 13zm8-5a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2a.5.5 0 0 1 .5.5zM3 8a.5.5 0 0 1-.5.5h-2a.5.5 0 0 1 0-1h2A.5.5 0 0 1 3 8zm10.657-5.657a.5.5 0 0 1 0 .707l-1.414 1.415a.5.5 0 1 1-.707-.708l1.414-1.414a.5.5 0 0 1 .707 0zm-9.193 9.193a.5.5 0 0 1 0 .707L3.05 13.657a.5.5 0 0 1-.707-.707l1.414-1.414a.5.5 0 0 1 .707 0zm9.193 2.121a.5.5 0 0 1-.707 0l-1.414-1.414a.5.5 0 0 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .707zM4.464 4.465a.5.5 0 0 1-.707 0L2.343 3.05a.5.5 0 1 1 .707-.707l1.414 1.414a.5.5 0 0 1 0 .708z"/>
          </symbol>
          <symbol id="three-dots" viewBox="0 0 16 16">
              <path d="M3 9.5a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm5 0a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z"/>
          </symbol>
          <symbol id="tools" viewBox="0 0 16 16">
              <path d="M1 0 0 1l2.2 3.081a1 1 0 0 0 .815.419h.07a1 1 0 0 1 .708.293l2.675 2.675-2.617 2.654A3.003 3.003 0 0 0 0 13a3 3 0 1 0 5.878-.851l2.654-2.617.968.968-.305.914a1 1 0 0 0 .242 1.023l3.356 3.356a1 1 0 0 0 1.414 0l1.586-1.586a1 1 0 0 0 0-1.414l-3.356-3.356a1 1 0 0 0-1.023-.242L10.5 9.5l-.96-.96 2.68-2.643A3.005 3.005 0 0 0 16 3c0-.269-.035-.53-.102-.777l-2.14 2.141L12 4l-.364-1.757L13.777.102a3 3 0 0 0-3.675 3.68L7.462 6.46 4.793 3.793a1 1 0 0 1-.293-.707v-.071a1 1 0 0 0-.419-.814L1 0zm9.646 10.646a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1-.708.708l-3-3a.5.5 0 0 1 0-.708zM3 11l.471.242.529.026.287.445.445.287.026.529L5 13l-.242.471-.026.529-.445.287-.287.445-.529.026L3 15l-.471-.242L2 14.732l-.287-.445L1.268 14l-.026-.529L1 13l.242-.471.026-.529.445-.287.287-.445.529-.026L3 11z"/>
          </symbol>
          <symbol id="ui-radios" viewBox="0 0 16 16">
              <path d="M7 2.5a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-1zM0 12a3 3 0 1 1 6 0 3 3 0 0 1-6 0zm7-1.5a.5.5 0 0 1 .5-.5h7a.5.5 0 0 1 .5.5v1a.5.5 0 0 1-.5.5h-7a.5.5 0 0 1-.5-.5v-1zm0-5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5zm0 8a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5zM3 1a3 3 0 1 0 0 6 3 3 0 0 0 0-6zm0 4.5a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3z"/>
          </symbol>
      </svg>

      <header class="navbar navbar-expand-lg bd-navbar sticky-top"> <!-- sticky-top"> -->
        <nav class="container-xxl bd-gutter flex-wrap flex-lg-nowrap" aria-label="Main navigation">
            <div class="bd-navbar-toggle">
                <button class="navbar-toggler p-2" type="button" data-bs-toggle="offcanvas" data-bs-target="#bdSidebar" aria-controls="bdSidebar" aria-label="Toggle docs navigation">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" class="bi" fill="currentColor" viewBox="0 0 16 16">
                        <path fill-rule="evenodd" d="M2.5 11.5A.5.5 0 0 1 3 11h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4A.5.5 0 0 1 3 7h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5zm0-4A.5.5 0 0 1 3 3h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5z"/>
                    </svg>

                    <span class="d-none fs-6 pe-1">Browse</span>
                </button>
            </div>

            <a class="navbar-brand p-0 me-0 me-lg-2" href="/" aria-label="{{site_name}}">
                <svg width="40" height="32" class="d-block my-1" aria-hidden="true">
                    <title>{{site_name}}</title>
                    <use xlink:href="#cuttles"></use>
                </svg>
            </a>

            <div class="d-flex">
                <div class="bd-search" id="docsearch" data-bd-docs-version="5.3"></div>
                <button class="navbar-toggler d-flex d-lg-none order-3 p-2" type="button" data-bs-toggle="offcanvas" data-bs-target="#bdNavbar" aria-controls="bdNavbar" aria-label="Toggle navigation">
                    <svg class="bi" aria-hidden="true">
                        <use xlink:href="#three-dots"></use>
                    </svg>
                </button>
            </div>

            <div class="offcanvas-lg offcanvas-end flex-grow-1" tabindex="-1" id="bdNavbar" aria-labelledby="bdNavbarOffcanvasLabel" data-bs-scroll="true">
                <div class="offcanvas-header px-4 pb-0">
                    <h5 class="offcanvas-title text-white" id="bdNavbarOffcanvasLabel">Bootstrap</h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="offcanvas" aria-label="Close" data-bs-target="#bdNavbar"></button>
                </div>

                <div class="offcanvas-body p-4 pt-0 p-lg-0">
                    <hr class="d-lg-none text-white-50">
                    <ul class="navbar-nav flex-row flex-wrap bd-navbar-nav">
                        <li class="nav-item col-6 col-lg-auto">
                            <a class="nav-link py-2 px-0 px-lg-2"  href="/space/blog">Blog</a>
                        </li>
                    </ul>

                    <hr class="d-lg-none text-white-50">

                    <ul class="navbar-nav flex-row flex-wrap ms-md-auto">
                        <li class="nav-item py-2 py-lg-1 col-12 col-lg-auto">
                            <div class="vr d-none d-lg-flex h-100 mx-lg-2 text-white"></div>
                            <hr class="d-lg-none my-2 text-white-50">
                        </li>

                        <li class="nav-item dropdown">
                            <button type="button" class="btn btn-link nav-link py-2 px-0 px-lg-2 dropdown-toggle" data-bs-toggle="dropdown" aria-expanded="false" data-bs-display="static">
                                <span class="d-lg-none" aria-hidden="true">Bootstrap</span>
                                <span class="visually-hidden">Tags&nbsp;</span>
                                 #tags 
                                <span class="visually-hidden">(quick listing)</span>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end">
                                <li>
                                    <h6 class="dropdown-header">Top 10 tags</h6>
                                </li>
                                <li>
                                    <a class="dropdown-item" href="/tags/foo">
                                        foo
                                    </a>
                                </li>
                                <li>
                                    <hr class="dropdown-divider">
                                </li>
                            </ul>
                        </li>

                        <li class="nav-item py-2 py-lg-1 col-12 col-lg-auto">
                            <div class="vr d-none d-lg-flex h-100 mx-lg-2 text-white"></div>
                            <hr class="d-lg-none my-2 text-white-50">
                        </li>

                        <li class="nav-item dropdown">
                            <button class="btn btn-link nav-link py-2 px-0 px-lg-2 dropdown-toggle d-flex align-items-center" id="bd-theme" type="button" aria-expanded="false" data-bs-toggle="dropdown" data-bs-display="static" aria-label="Toggle theme (auto)">
                                <svg class="bi my-1 theme-icon-active">
                                    <use href="#circle-half"></use>
                                </svg>
                                <span class="d-lg-none ms-2" id="bd-theme-text">Toggle theme</span>
                            </button>
                            <ul class="dropdown-menu dropdown-menu-end" aria-labelledby="bd-theme-text">
                                <li>
                                    <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="light" aria-pressed="false">
                                        <svg class="bi me-2 opacity-50">
                                            <use href="#sun-fill"></use>
                                        </svg>

                                                          Light
                                                          
                                        <svg class="bi ms-auto d-none">
                                            <use href="#check2"></use>
                                        </svg>
                                    </button>
                                </li>
                                <li>
                                    <button type="button" class="dropdown-item d-flex align-items-center" data-bs-theme-value="dark" aria-pressed="false">
                                        <svg class="bi me-2 opacity-50">
                                            <use href="#moon-stars-fill"></use>
                                        </svg>

                                                          Dark
                                                          
                                        <svg class="bi ms-auto d-none">
                                            <use href="#check2"></use>
                                        </svg>
                                    </button>
                                </li>
                                <li>
                                    <button type="button" class="dropdown-item d-flex align-items-center active" data-bs-theme-value="auto" aria-pressed="true">
                                        <svg class="bi me-2 opacity-50">
                                            <use href="#circle-half"></use>
                                        </svg>

                                                          Auto
                                                          
                                        <svg class="bi ms-auto d-none">
                                            <use href="#check2"></use>
                                        </svg>
                                    </button>
                                </li>
                            </ul>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
    </header>

    <div class="container-xxl bd-gutter mt-3 my-md-4 bd-layout">
        <aside class="bd-sidebar">
            <div class="offcanvas-lg offcanvas-start" tabindex="-1" id="bdSidebar" aria-labelledby="bdSidebarOffcanvasLabel">
                <div class="offcanvas-header border-bottom">
                    <h5 class="offcanvas-title" id="bdSidebarOffcanvasLabel">Browse docs</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="offcanvas" aria-label="Close" data-bs-target="#bdSidebar"></button>
                </div>

                <div class="offcanvas-body">
                    <nav class="bd-links w-100" id="bd-docs-nav" aria-label="Docs navigation">
                        <ul class="bd-links-nav list-unstyled mb-0 pb-3 pb-md-2 pe-lg-2">
                            <li class="bd-links-group py-2">
                                <strong class="bd-links-heading d-flex w-100 align-items-center fw-semibold">
                                    <svg class="bi me-2" style="color: var(--bs-blue);" aria-hidden="true">
                                        <use xlink:href="#calendar3"></use>
                                    </svg>
                                    <a href="/meta/archive">Archives</a> 
                                </strong>

                                <ul class="list-unstyled fw-normal pb-2 small">
                                    <li>
                                        <a href="/meta/archive/2024" class="bd-links-link d-inline-block rounded">2024</a>
                                    </li>
                                </ul>
                            </li>
                            <!-- separator -->
                            <li class="bd-links-span-all mt-1 mb-3 mx-4 border-top"></li>
                            <li class="bd-links-span-all">
                                <a href="/meta" class="bd-links-link d-inline-block rounded small ">Meta</a>
                            </li>
                        </ul>
                    </nav>

                </div>
            </div>
        </aside>

        <main class="bd-main order-1">
            <div class="bd-intro pt-2 ps-lg-2">
                <div class="d-md-flex flex-md-row align-items-center justify-content-between">
                    <h1 class="bd-title mb-0" id="content">{{!headers["title"]}}</h1>
                </div>
            </div>

            <div class="bd-toc mt-3 mb-5 my-lg-0 mb-lg-5 px-sm-1 text-body-secondary">
                <button class="btn btn-link p-md-0 mb-2 mb-md-0 text-decoration-none bd-toc-toggle d-md-none" type="button" data-bs-toggle="collapse" data-bs-target="#tocContents" aria-expanded="false" aria-controls="tocContents">

                                On this page
                                
                    <svg class="bi d-md-none ms-2" aria-hidden="true">
                        <use xlink:href="#chevron-expand"></use>
                    </svg>
                </button>
                <strong class="d-none d-md-block h6 my-2 ms-3">On this page</strong>
                <hr class="d-none d-md-block my-2 ms-3">
                <div class="collapse bd-toc-collapse" id="tocContents">
                    <nav id="TableOfContents">
                        <ul>
                            <!-- headings for TOC
                            <li>
                                <a href="#anchor">Heading</a>
                            </li>
                            -->
                        </ul>
                    </nav>
                </div>
            </div>

            <div class="bd-content ps-lg-2">
              <!-- Body Text-->
              {{!body}}
            </div>
        </main>
    </div>

    <footer class="bd-footer py-4 py-md-5 mt-5 bg-body-tertiary">
        <div class="container py-4 py-md-5 px-4 px-md-3 text-body-secondary">
            <div class="row">
                <!-- Footer logo -->
                <div class="col-lg-3 mb-3">
                    <a class="d-inline-flex align-items-center mb-2 text-body-emphasis text-decoration-none" href="/" aria-label="Bootstrap">
                        <svg width="40" height="32" class="d-block me-2" style="color: var(--bs-black);" aria-hidden="true">
                            <title>{{site_name}}</title>
                            <use xlink:href="#cuttles"></use>
                        </svg>
                        <span class="fs-5">{{site_name}}</span>
                    </a>
                    <ul class="list-unstyled small">
                        <li class="mb-2">
                            Code licensed 
                            <a href="https://github.com/rcarmo/sushy/blob/main/LICENSE" target="_blank" rel="license noopener">MIT</a>
                        </li>
                    </ul>
                </div>
                <!-- Footer Links -->
<% 
columns = {
    "Themeing": {
        "Bootstrap": "https://getbootstrap.com/docs/5.3/getting-started/introduction/",
        "Icons": "https://icons.getbootstrap.com",
    },
    "Reference": {
        "Hy": "http://hylang.org",
    },
    "Projects": {
       "Sushy": "https://github.com/rcarmo/sushy",
    }
}
index = 0
%>
% for heading, links in columns.items():
% if not index:
                <div class="col-lg-3 mb-3">
% else:
                <div class="col-6 col-lg-2 mb-3">
% end
                    <h5>{{heading}}</h5>
% index = index + 1
% for label, link in links.items():
                    <ul class="list-unstyled">
                        <li class="mb-2">
                            <a href="{{link}}" target="_blank" rel="noopener">{{label}}</a>
                        </li>
                    </ul>
% end
                </div>
% end
            </div>
        </div>
    </footer>

    <script src="/static/js/bootstrap.bundle.min.js"></script>

    <div class="position-fixed" aria-hidden="true">
        <input type="text" tabindex="-1">
    </div>

</body>
</html>
