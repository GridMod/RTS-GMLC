
# All potential sections. Should match the HTML report.
sections = c('1. Total database annual generation stack', 
             '2. Zonal annual generation stacks', 
             '3. Regional annual generation stacks',
             '4. Individual region, annual generation stacks', 
             '5. Total database key period generation stacks', 
             '6. Zonal key period generation stacks',
             '7. Regional key period generation stacks', 
             '8. Average daily curtailment', 
             '9. Average daily curtailment, by type', 
             '10. Average interval curtailment',
             '11. Average interval curtailment, by type',
             '12. Annual generation table',
             '13. Annual curtailment table',
             '14. Annual cost table', 
             '15. Region and zone flow table', 
             '16. Interface flow table', 
             '17. Interface flow plot', 
             '18. Key period interface flow plot', 
             '19. Annual reserves table', 
             '20. Reserves plot', 
             '21. Reserves provision stack by reserve region', 
             '22. Region and zone generation table',
             '23. Capacity factor table', 
             '24. Price duration curve', 
             '25. Zonal committment and dispatch plots',
             '26. Regional committment and dispatch plots')

# Create a named integer list of sections
sectionList = setNames(1:length(sections), sections)

# Potential generation type colors for generation stacks
plotColors = c('firebrick', 'gray20', 'khaki1', 'lightblue', 'darkolivegreen4', 'lightpink', 'mediumpurple3', 'orchid4', 'gray60',
               'darkorange2', 'goldenrod1', 'steelblue3', 'red', 'gray45', 'mediumpurple2', 'darkslateblue', 'gray50', 'goldenrod2')
