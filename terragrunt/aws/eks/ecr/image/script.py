import boto3

# Initialize EventBridge client
events_client = boto3.client('events')

def get_rules_without_input_transformer():
    # Get all event buses (including the default)
    buses = events_client.list_event_buses()['EventBuses']
    
    matched_rules = []
    
    # Iterate through each bus
    for bus in buses:
        bus_name = bus['Name']
        
        # List rules for each bus
        rules = events_client.list_rules(EventBusName=bus_name)['Rules']
        
        for rule in rules:
            rule_name = rule['Name']
            
            # Get detailed rule information
            targets = events_client.list_targets_by_rule(Rule=rule_name, EventBusName=bus_name)['Targets']
            
            # Check if any target has an input transformer
            has_input_transformer = any('InputTransformer' in target for target in targets)
            
            # Only add rules without input transformers
            if not has_input_transformer:
                matched_rules.append({
                    'RuleName': rule_name,
                    'EventBusName': bus_name
                })
    
    return matched_rules

if __name__ == "__main__":
    rules = get_rules_without_input_transformer()
    for rule in rules:
        print(f"EventBridge Rule without Input Transformer: {rule['RuleName']} (Bus: {rule['EventBusName']})")

